import SwiftUI
import CoreLocation
import Combine

// 搜尋類別枚舉
enum FoodCategory: String, CaseIterable {
    case all = "全部"
    case restaurant = "餐廳"
    case japanese = "日式料理"
    case korean = "韓式料理"
    case italian = "義式料理"
    case thai = "泰式料理"
    case chinese = "中式料理"
    case american = "美式料理"
    case cafe = "咖啡廳"
    case fastFood = "速食"
    case hotpot = "火鍋"
    case bbq = "燒烤"
    case ramen = "拉麵"
    case izakaya = "居酒屋"
    case breakfast = "早午餐"
    case dessert = "甜點"
    case bubbleTea = "珍珠奶茶"
    case vegetarian = "素食"

    // Yelp API 對應的 category alias
    var yelpCategory: String {
        switch self {
        case .all: return "restaurants"
        case .restaurant: return "restaurants"
        case .japanese: return "japanese"
        case .korean: return "korean"
        case .italian: return "italian"
        case .thai: return "thai"
        case .chinese: return "chinese"
        case .american: return "newamerican,tradamerican"
        case .cafe: return "cafes"
        case .fastFood: return "hotdogs" // Yelp uses 'hotdogs' for fast food
        case .hotpot: return "hotpot"
        case .bbq: return "bbq"
        case .ramen: return "ramen"
        case .izakaya: return "izakaya"
        case .breakfast: return "breakfast_brunch"
        case .dessert: return "desserts"
        case .bubbleTea: return "bubbletea"
        case .vegetarian: return "vegetarian"
        }
    }
}

// 排序方式
enum SortOption: String, CaseIterable {
    case bestMatch = "綜合排序"
    // case rating = "評分優先" // Temporarily removed due to lack of rating data
    case distance = "距離優先"
    
    // Yelp API 對應的 sort_by value
    var yelpSortBy: String {
        switch self {
        case .bestMatch: return "best_match"
        // case .rating: return "rating"
        case .distance: return "distance"
        }
    }
}

@MainActor
class RestaurantViewModel: NSObject, ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var likedRestaurants: [Restaurant] = []
    
    @Published var searchRadius: Double = 3000
    @Published var selectedCategory: FoodCategory = .all
    @Published var sortOption: SortOption = .distance
    @Published var showOnlyOpen: Bool = false
    @Published var minimumRating: Double = 0.0
    
    private let locationManager = CLLocationManager()
    private let yelpAPIService = YelpAPIService()
    private var currentLocation: CLLocation?
    private var allRestaurants: [Restaurant] = []
    private var currentOffset = 0
    private var viewedRestaurantIDs: Set<String> = []
    
    private let likedRestaurantsKey = "likedRestaurants"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // 降低精度要求以提高成功率和速度
        loadLikedRestaurants()
    }
    
    // MARK: - Persistence
    
    private func saveLikedRestaurants() {
        if let encoded = try? JSONEncoder().encode(likedRestaurants) {
            UserDefaults.standard.set(encoded, forKey: likedRestaurantsKey)
        }
    }
    
    private func loadLikedRestaurants() {
        if let data = UserDefaults.standard.data(forKey: likedRestaurantsKey),
           let decoded = try? JSONDecoder().decode([Restaurant].self, from: data) {
            likedRestaurants = decoded
        }
    }
    
    func requestLocationAndSearch(resetViewed: Bool = true) {
        // Reset state for a new search
        self.currentLocation = nil
        self.errorMessage = nil
        if resetViewed {
            self.viewedRestaurantIDs.removeAll()
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            self.errorMessage = "位置權限已被拒絕。請至「設定」開啟權限。"
        @unknown default:
            break // Do nothing
        }
    }
    
    func loadMoreRestaurants() {
        guard let location = currentLocation else { return }
        
        Task {
            isLoading = true
            await searchNearbyRestaurants(location: location, isLoadMore: true)
        }
    }
    
    private func searchNearbyRestaurants(location: CLLocation, isLoadMore: Bool = false) async {
        let offset = isLoadMore ? currentOffset + 50 : 0
        
        do {
            let yelpBusinesses = try await yelpAPIService.searchBusinesses(
                coordinate: location.coordinate,
                radius: Int(searchRadius),
                categories: selectedCategory.yelpCategory,
                limit: 50, // Explicitly set limit
                offset: offset,
                sortBy: sortOption.yelpSortBy,
                openNow: showOnlyOpen
            )
            
            let mappedRestaurants = mapYelpBusinesses(yelpBusinesses, from: location)
            
            if isLoadMore {
                // If no more results returned, handle gracefully (maybe show a toast, but for now just don't append)
                if !mappedRestaurants.isEmpty {
                    self.allRestaurants.append(contentsOf: mappedRestaurants)
                    self.currentOffset = offset
                    self.applyFiltersAndSort(resetIndex: false)
                }
            } else {
                self.allRestaurants = mappedRestaurants
                self.currentOffset = 0
                self.applyFiltersAndSort(resetIndex: true)
            }
            
        } catch let error as YelpAPIService.YelpAPIError {
            switch error {
            case .invalidURL:
                self.errorMessage = "無效的 API 端點"
            case .requestFailed(let underlyingError):
                self.errorMessage = "網路請求失敗: \(underlyingError.localizedDescription)"
            case .invalidResponse:
                self.errorMessage = "從伺服器收到無效的回應。請檢查您的 API Key 是否正確。"
            case .decodingError:
                self.errorMessage = "解析伺服器資料失敗。"
            }
        } catch {
            self.errorMessage = "發生未知錯誤: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }

    private func mapYelpBusinesses(_ businesses: [YelpBusiness], from location: CLLocation) -> [Restaurant] {
        return businesses.map { business -> Restaurant in
            // Debug Log: Check rating data
            // print("Restaurant: \(business.name), Rating: \(String(describing: business.rating))")
            
            let businessLocation = CLLocation(
                latitude: business.coordinates.latitude,
                longitude: business.coordinates.longitude
            )
            let distance = location.distance(from: businessLocation)
            
            return Restaurant(
                id: business.id, // Use Yelp's unique ID
                name: business.name,
                category: business.categories?.first?.title, // Use actual category title
                imageUrl: business.imageUrl,
                latitude: business.coordinates.latitude,
                longitude: business.coordinates.longitude,
                distance: distance,
                phoneNumber: business.displayPhone,
                rawPhoneNumber: business.phone,
                rating: business.rating,
                isOpenNow: business.isClosed == false
            )
        }
    }
    
    func applyFiltersAndSort(resetIndex: Bool = true) {
        var filtered = allRestaurants
        
        // Filter out viewed restaurants
        filtered = filtered.filter { !viewedRestaurantIDs.contains($0.id) }
        
        // Note: Radius and category are now filtered by the API call itself.
        // We can keep client-side filtering for immediate feedback if needed.
        
        // showOnlyOpen is now handled by API
        // if showOnlyOpen {
        //    filtered = filtered.filter { $0.isOpenNow }
        // }
        
        if minimumRating > 0 {
            filtered = filtered.filter {
                if let rating = $0.rating {
                    return rating >= minimumRating
                }
                return false
            }
        }
        
        // Sorting is also handled by the API, but we can re-sort if needed.
        // For simplicity, we trust the API's sorting for now.
        
        // Smart Sort: Client-side optimization for "Best Match"
        if sortOption == .bestMatch {
            filtered.sort { (r1, r2) -> Bool in
                func calculateScore(_ r: Restaurant) -> Double {
                    var score: Double = 0
                    
                    // Rating weight (0-10 points)
                    if let rating = r.rating, rating > 0 {
                        score += rating * 2.0
                    }
                    
                    // Image weight (3 points)
                    if r.imageUrl != nil {
                        score += 3.0
                    }
                    
                    // Distance penalty (0.5 points per km)
                    score -= (r.distance / 1000.0) * 0.5
                    
                    return score
                }
                
                return calculateScore(r1) > calculateScore(r2)
            }
        }
        
        restaurants = filtered
        if resetIndex {
            currentIndex = 0
        }
    }
    
    func handleSwipe(direction: SwipeDirection) {
        guard currentIndex < restaurants.count else { return }
        
        let restaurant = restaurants[currentIndex]
        
        // Mark as viewed
        viewedRestaurantIDs.insert(restaurant.id)
        
        if direction == .right {
            if !likedRestaurants.contains(where: { $0.id == restaurant.id }) {
                likedRestaurants.append(restaurant)
                saveLikedRestaurants()
            }
        }
        
        currentIndex += 1
    }
    
    func removeLikedRestaurant(_ restaurant: Restaurant) {
        if let index = likedRestaurants.firstIndex(where: { $0.id == restaurant.id }) {
            likedRestaurants.remove(at: index)
            saveLikedRestaurants()
        }
    }
}

extension RestaurantViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Stop location updates to save battery
        manager.stopUpdatingLocation()
        
        // Ensure we don't start a new search if one is already running
        guard self.currentLocation == nil else { return }
        
        self.currentLocation = location
        
        Task {
            // Now that we have a location, set loading to true and start the search
            self.isLoading = true
            await searchNearbyRestaurants(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = "定位失敗: \(error.localizedDescription)"
        self.isLoading = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}
