
import Foundation

enum APIKeyManager {
    static var yelpAPIKey: String {
        guard let value = Bundle.main.infoDictionary?["YelpAPIKey"] as? String else {
            fatalError("Couldn't find key 'YelpAPIKey' in your project's Info settings. Make sure you have added it to the Target's Info tab.")
        }
        
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedValue.isEmpty else {
            fatalError("Your 'YelpAPIKey' in the project's Info settings cannot be empty.")
        }
        
        if trimmedValue.starts(with: "YOUR_") {
            fatalError("Please replace 'YOUR_API_KEY' with your actual Yelp API key in the project's Info settings.")
        }
        
        return trimmedValue
    }
}
