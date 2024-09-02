//
//  CoreDataController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 15/5/2024.
//

import UIKit
import CoreData

class CoreDataController: NSObject, NSFetchedResultsControllerDelegate, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var allPlansFetchedResultsController: NSFetchedResultsController<Plan>?
    var allSavedLocationsFetchedResultsController: NSFetchedResultsController<Location>?
    
    /// Creates a persistent container and attempts to load the persistent stores.
    override init() {
        persistentContainer = NSPersistentContainer(name: "PlanDataModel")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error {
                fatalError("Failed to load Core Data stack with error: \(error)")
            }
        }
        
        super.init()
    }
    
    /// Saves any changes in the view context of the persistent container to the Core Data.
    func cleanup() {
        // Check if there are any unsaved changes in the view context.
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save data to Core Data with error \(error)")
            }
        }
    }
    
    /// Notifies the appropriate listeners when the content of the fetched results controller changes.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // If the changed controller is for plans, notify the listeners interested in plan changes.
        if controller == allPlansFetchedResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .plan || listener.listenerType == .all {
                    listener.onPlanListChange(change: .update, planList: fetchAllPlans())
                }
            }
        }
        // If the changed controller is for saved locations, notify the listeners interested in location changes.
        else if controller == allSavedLocationsFetchedResultsController {
            listeners.invoke { listener in
                if listener.listenerType == .location || listener.listenerType == .all {
                    listener.onSavedLocationsListChange(change: .update, savedLocationsList: fetchAllSavedLocations())
                }
            }
        }
    }
    
    /// Adds a listener to the database.
    /// - Parameter listener: The listener to add.
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        // Notify the listener for plan updates
        if listener.listenerType == .plan || listener.listenerType == .all {
            listener.onPlanListChange(change: .update, planList: fetchAllPlans())
        }
        
        // Notify the listener for saved location updates
        if listener.listenerType == .location || listener.listenerType == .all {
            listener.onSavedLocationsListChange(change: .update, savedLocationsList: fetchAllSavedLocations())
        }
    }
    
    /// Removes a listener from the database.
    /// - Parameter listener: The listener to remove.
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    
    /// Fetches all plans from the Core Data.
    func fetchAllPlans() -> [Plan] {
        if allPlansFetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Plan> = Plan.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [nameSortDescriptor]
            
            allPlansFetchedResultsController = NSFetchedResultsController<Plan>( fetchRequest:fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            allPlansFetchedResultsController?.delegate = self
            
            do {
                try allPlansFetchedResultsController?.performFetch() }
            catch {
                print("Fetch Request failed: \(error)")
            }
        }
        if let plans = allPlansFetchedResultsController?.fetchedObjects {
            return plans
        }
        return [Plan]()
    }
    
    /// Adds a new plan to the Core Data.
    func addPlan(name: String, start: Date, end: Date) -> Plan {
        let plan = NSEntityDescription.insertNewObject(forEntityName: "Plan",
                                                       into: persistentContainer.viewContext) as! Plan
        plan.name = name
        plan.start = start
        plan.end = end
        
        return plan
    }
    
    /// Deletes a plan from the Core Data.
    func deletePlan(plan: Plan) {
        persistentContainer.viewContext.delete(plan)
    }
    
    /// Adds a location to a plan's itinerary.
    /// - Parameters:
    ///   - location: The location to add.
    ///   - plan: The plan to add the location to.
    /// - Returns: true if the location was added, false if the location was already in the itinerary.
    func addLocationToPlan(location: Location, plan: Plan) -> Bool {
        guard let itinerary = plan.itinerary, itinerary.contains(location) == false else {
            return false
        }
        
        plan.addToItinerary(location)
        return true
    }
    
    /// Removes a location from a plan's itinerary.
    /// - Parameters:
    ///   - location: The location to remove.
    ///   - plan: The plan to remove the location from.
    func removeLocationFromPlan(location: Location, plan: Plan) {
        plan.removeFromItinerary(location)
    }
    
    
    /// Fetches all saved locations from the Core Data.
    func fetchAllSavedLocations() -> [Location] {
        if allSavedLocationsFetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.sortDescriptors = [nameSortDescriptor]
            
            allSavedLocationsFetchedResultsController = NSFetchedResultsController<Location>( fetchRequest:fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            allSavedLocationsFetchedResultsController?.delegate = self
            
            do {
                try allSavedLocationsFetchedResultsController?.performFetch() }
            catch {
                print("Fetch Request failed: \(error)")
            }
        }
        if let locations = allSavedLocationsFetchedResultsController?.fetchedObjects {
            return locations
        }
        return [Location]()
    }
    
    /// Fetches a specific location from the Core Data.
    func fetchLocation(locationData: LocationData) -> Location? {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND address == %@", locationData.name, locationData.address)
        
        do {
            let locations = try persistentContainer.viewContext.fetch(fetchRequest)
            return locations.first
        } catch {
            print("Failed to fetch location: \(error)")
            return nil
        }
    }

    /// Saves a location to the Core Data.
    /// - Parameter locationData: The data of the location to save.
    /// - Returns: The saved location.
    func saveLocation(locationData: LocationData) -> Location {
        let location = NSEntityDescription.insertNewObject(forEntityName: "Location",
                                                       into: persistentContainer.viewContext) as! Location
        location.name = locationData.name
        location.address = locationData.address
        
        // Convert latitude and longitude from String to Double
        if let latitude = Double(locationData.latitude), let longitude = Double(locationData.longitude) {
            location.latitude = latitude
            location.longitude = longitude
        }  else {
            print("Error: Invalid latitude or longitude value")
        }
        
        return location
    }
    
    /// Unsaves a location from the Core Data.
    /// - Parameter location: The location to unsave.
    func unsaveLocation(location: Location) {
        persistentContainer.viewContext.delete(location)
    }
}
