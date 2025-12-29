import Foundation
import MapKit

struct Restaurant: Identifiable, Hashable, Codable {
    let id: String // Changed from UUID to String to match Yelp's ID
    let name: String
    let category: String?
    let imageUrl: URL?   // Added for Yelp image
    let latitude: Double
    let longitude: Double
    let distance: Double
    let phoneNumber: String?
    let rawPhoneNumber: String? // Added for calling
    let rating: Double?
    let isOpenNow: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    // Conformance to Hashable
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
