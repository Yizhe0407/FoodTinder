
import Foundation
import CoreLocation

// MARK: - Yelp API Service

final class YelpAPIService {
    
    private let apiKey = APIKeyManager.yelpAPIKey
    private let baseURL = "https://api.yelp.com/v3/businesses/search"
    
    enum YelpAPIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
    }
    
    /// Searches for businesses on Yelp with various criteria.
    /// - Parameters:
    ///   - coordinate: The geographic coordinate to search around.
    ///   - radius: The search radius in meters.
    ///   - categories: The categories to filter by (e.g., "restaurants", "bars"). Defaults to "restaurants".
    ///   - limit: The maximum number of results to return. Maximum is 50.
    ///   - sortBy: The sorting method (e.g., "best_match", "rating", "distance").
    /// - Returns: An array of `YelpBusiness` objects.
    /// - Throws: A `YelpAPIError` if the request fails.
    func searchBusinesses(
        coordinate: CLLocationCoordinate2D,
        radius: Int,
        categories: String = "restaurants",
        limit: Int = 50,
        offset: Int = 0,
        sortBy: String = "best_match",
        openNow: Bool = false
    ) async throws -> [YelpBusiness] {
        
        let urlString = "\(baseURL)?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&radius=\(radius)&categories=\(categories)&limit=\(limit)&offset=\(offset)&sort_by=\(sortBy)&locale=zh_TW&open_now=\(openNow)"
        
        guard let url = URL(string: urlString) else {
            throw YelpAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw YelpAPIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            do {
                let searchResponse = try decoder.decode(YelpSearchResponse.self, from: data)
                return searchResponse.businesses
            } catch {
                throw YelpAPIError.decodingError(error)
            }
        } catch {
            throw YelpAPIError.requestFailed(error)
        }
    }
}
