//
//  Plan+CoreDataProperties.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 17/5/2024.
//
//

import Foundation
import CoreData


extension Plan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Plan> {
        return NSFetchRequest<Plan>(entityName: "Plan")
    }

    @NSManaged public var end: Date?
    @NSManaged public var name: String?
    @NSManaged public var start: Date?
    @NSManaged public var itinerary: NSSet?

}

// MARK: Generated accessors for itinerary
extension Plan {

    @objc(addItineraryObject:)
    @NSManaged public func addToItinerary(_ value: Location)

    @objc(removeItineraryObject:)
    @NSManaged public func removeFromItinerary(_ value: Location)

    @objc(addItinerary:)
    @NSManaged public func addToItinerary(_ values: NSSet)

    @objc(removeItinerary:)
    @NSManaged public func removeFromItinerary(_ values: NSSet)

}

extension Plan : Identifiable {

}
