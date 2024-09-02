//
//  ItineraryTableViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit

class ItineraryTableViewController: UITableViewController, DatabaseListener {
    var listenerType: ListenerType = .plan
    
    var plan: Plan?
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = plan?.name
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        tableView.reloadData()
    }
    
    /// Add a listener when the view is about to appear on the screen.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }

    /// Remove the listener when the view is about to disappear from the screen.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onPlanListChange(change: DatabaseChange, planList: [Plan]) {
        if let updatedPlan = planList.first(where: { $0.objectID == plan?.objectID }) {
            plan = updatedPlan
            tableView.reloadData()
        }
    }
    
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location]) {
        // Do nothing
    }

    // MARK: - Table view data source
    /// Returns the number of sections in the table view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// Returns the number of locations in the itinerary.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plan?.itinerary?.count ?? 0
    }

    /// Returns a cell with the appropriate location data for the specified row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        if let location = plan?.itinerary?.allObjects[indexPath.row] as? Location {
            cell.textLabel?.text = location.name
            cell.detailTextLabel?.text = location.address
        }
        return cell
    }

    /// Returns whether the specified row can be edited.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    /// Deletes a specified location from the itinerary.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let location = plan?.itinerary?.allObjects[indexPath.row] as? Location {
                databaseController?.removeLocationFromPlan(location: location, plan: plan!)
                tableView.reloadData()
            }
        }
    }

    /*
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
     */

    // MARK: - Navigation
    /// Prepares for a segue to AddSavedLocationsTableViewController and ItineraryMapViewController by passing the selected plan.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showSavedLocationsSegue" {
            if let destination = segue.destination as? AddSavedLocationsTableViewController {
                destination.plan = plan
            }
        }
        if segue.identifier == "showItineraryMapSegue" {
            if let destination = segue.destination as? ItineraryMapViewController {
                destination.plan = plan
            }
        }
    }

}
