
import Foundation

// MARK: - Yelp API Response Structures

struct YelpSearchResponse: Codable {
    let businesses: [YelpBusiness]
    let total: Int
}

struct YelpCategory: Codable {
    let alias: String?
    let title: String?
}

struct YelpBusiness: Codable {
    let id: String
    let name: String
    let imageUrl: URL?
    let isClosed: Bool?
    let url: String? // Added url field which might be useful
    let rating: Double?
    let reviewCount: Int?
    let categories: [YelpCategory]? // Added categories
    let coordinates: YelpCoordinates
    let price: String?
    let location: YelpLocation
    let phone: String?
    let displayPhone: String?
    let distance: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageUrl = "image_url"
        case isClosed = "is_closed"
        case url
        case rating
        case reviewCount = "review_count"
        case categories
        case coordinates
        case price
        case location
        case phone
        case displayPhone = "display_phone"
        case distance
    }
    
    // Custom initializer for robust decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isClosed = try container.decodeIfPresent(Bool.self, forKey: .isClosed)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        categories = try container.decodeIfPresent([YelpCategory].self, forKey: .categories)
        coordinates = try container.decode(YelpCoordinates.self, forKey: .coordinates)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        location = try container.decode(YelpLocation.self, forKey: .location)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        displayPhone = try container.decodeIfPresent(String.self, forKey: .displayPhone)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        
        // Robustly decode image_url
        if let imageUrlString = try container.decodeIfPresent(String.self, forKey: .imageUrl),
           !imageUrlString.isEmpty {
            self.imageUrl = URL(string: imageUrlString)
        } else {
            self.imageUrl = nil
        }
    }
}

struct YelpCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct YelpLocation: Codable {
    let address1: String?
    let address2: String?
    let address3: String?
    let city: String?
    let zipCode: String?
    let country: String?
    let state: String?
    let displayAddress: [String]?

    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city, country, state
        case zipCode = "zip_code"
        case displayAddress = "display_address"
    }
}
