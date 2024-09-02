//
//  NearbyLocationsData.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 26/4/2024.
//

import Foundation


/// NearbyLocationsData represents the response from the Google Places Nearby Search and Text Search APIs.
class NearbyLocationsData: NSObject, Decodable {
    /// An array of NearbyLocation objects representing the results from the API response.
    var results: [NearbyLocation]?
    
    /// NearbyLocation represents a single location returned in the nearby search results.
    struct NearbyLocation: Decodable {
        /// The unique identifier for the place.
        let place_id: String
    }
}
