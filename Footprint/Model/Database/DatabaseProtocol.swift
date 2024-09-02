//
//  DatabaseProtocol.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 15/5/2024.
//

import Foundation

/// Represents the types of changes that can occur in the database.
enum DatabaseChange {
    case add
    case remove
    case update
}

/// Represents the types of listeners for database updates.
enum ListenerType {
    case plan
    case location
    case all
}

/// Defines the required methods and properties for a database listener.
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onPlanListChange(change: DatabaseChange, planList: [Plan])
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location])
}

/// Defines the required methods for interacting with the database.
protocol DatabaseProtocol: AnyObject {
    func cleanup()
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func fetchAllPlans() -> [Plan]
    func addPlan(name: String, start: Date, end: Date) -> Plan
    func deletePlan(plan: Plan)
    func addLocationToPlan(location: Location, plan: Plan) -> Bool
    func removeLocationFromPlan(location: Location, plan: Plan)
    
    func fetchLocation(locationData: LocationData) -> Location?
    func saveLocation(locationData: LocationData) -> Location
    func unsaveLocation(location: Location)
}

