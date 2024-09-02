//
//  LocationData.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit

/// LocationData represents the response from the Google Places Place Details and Place Photos API.
class LocationData: NSObject, Decodable {
    var name: String
    var address: String
    var latitude: String
    var longitude: String
    var imageURL: String?
//    var website: String?
//    var url: String?
//    var reviews: [Review]?
//    var priceLevel: Int?
    var desc: String?

    var image: UIImage?
    var imageIsDownloading: Bool = false
    
    /// Nested struct to decode latitude and longitude data.
    private struct Geometry: Decodable {
        struct Location: Decodable {
            let lat: Double
            let lng: Double
        }
        let location: Location
    }
    
    /// Nested struct to decode photo data.
    private struct Photo: Decodable {
        let photo_reference: String
    }
    
    /// Nested struct to decode opening hours data.
    private struct OpeningHours: Decodable {
        let weekday_text: [String]
    }
    
    /// Nested struct to decode review data.
//    struct Review: Decodable {
//        let author_name: String
//        let rating: Int
//        let text: String
//        let time: Int
//    }
    
    /// Enum to define coding keys for decoding location data.
    private enum LocationKeys: String, CodingKey {
        case result
        case name
        case address = "formatted_address"
        case geometry
        case photos
//        case website
//        case url
//        case reviews
//        case priceLevel = "price_level"
        case opening_hours
    }
    
    /// Enum to define coding keys for decoding geometry data.
    private enum GeometryKeys: String, CodingKey {
        case location
    }
    
    /// Enum to define coding keys for decoding latitude and longitude.
    private enum LocationDataKeys: String, CodingKey {
        case lat
        case lng
    }
    
    /// Initializer to decode the location data from a decoder.
    /// - Parameter decoder: The decoder containing the location data.
    required init(from decoder: Decoder) throws {
        // Get the container for the top level of the response
        let container = try decoder.container(keyedBy: LocationKeys.self)
        let resultContainer = try container.nestedContainer(keyedBy: LocationKeys.self, forKey: .result)
        
        // Get the location name and address
        name = try resultContainer.decode(String.self, forKey: .name)
        address = try resultContainer.decode(String.self, forKey: .address)
//        website = try? resultContainer.decode(String.self, forKey: .website)
//        url = try? resultContainer.decode(String.self, forKey: .url)
//        reviews = try? resultContainer.decode([Review].self, forKey: .reviews)
//        priceLevel = try? resultContainer.decode(Int.self, forKey: .priceLevel)
        
        // Get the geometry container
        let geometryContainer = try resultContainer.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        let locationContainer = try geometryContainer.nestedContainer(keyedBy: LocationDataKeys.self, forKey: .location)
        latitude = String(try locationContainer.decode(Double.self, forKey: .lat))
        longitude = String(try locationContainer.decode(Double.self, forKey: .lng))
        
        // Get the photos if available
        if let photos = try? resultContainer.decode([Photo].self, forKey: .photos), let firstPhoto = photos.first {
            imageURL = firstPhoto.photo_reference
        }
        
        // Get the opening hours if available and convert to string format
        if let openingHoursContainer = try? resultContainer.decode(OpeningHours.self, forKey: .opening_hours) {
            desc = openingHoursContainer.weekday_text.joined(separator: "\n")
        }
    }
}
