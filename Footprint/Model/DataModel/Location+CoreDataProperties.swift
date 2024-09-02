//
//  Location+CoreDataProperties.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 17/5/2024.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var itinerary: NSSet?

}

// MARK: Generated accessors for itinerary
extension Location {

    @objc(addItineraryObject:)
    @NSManaged public func addToItinerary(_ value: Plan)

    @objc(removeItineraryObject:)
    @NSManaged public func removeFromItinerary(_ value: Plan)

    @objc(addItinerary:)
    @NSManaged public func addToItinerary(_ values: NSSet)

    @objc(removeItinerary:)
    @NSManaged public func removeFromItinerary(_ values: NSSet)

}

extension Location : Identifiable {

}
