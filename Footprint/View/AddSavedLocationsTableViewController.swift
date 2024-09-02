//
//  AddSavedLocationsTableViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit

class AddSavedLocationsTableViewController: UITableViewController, DatabaseListener {

    let CELL_LOCATION = "savedLocationCell"
    var savedLocations = [Location]()
    var plan: Plan?
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .location
    
    func onPlanListChange(change: DatabaseChange, planList: [Plan]) {
        // Do nothing
    }
    
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location]) {
        savedLocations = savedLocationsList
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleEditingMode))
        
        tableView.allowsMultipleSelectionDuringEditing = true
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
    
    /// Toggles the table view's editing mode to select multiple locations to add to the itinerary.
    @objc func toggleEditingMode() {
        if tableView.isEditing {
            // When 'Done' is tapped, add the selected locations to the itinerary
            if let selectedRows = tableView.indexPathsForSelectedRows {
                for indexPath in selectedRows {
                    let location = savedLocations[indexPath.row]
                    let _ = databaseController?.addLocationToPlan(location: location, plan: plan!)
                }
                cancelEditingMode()
                navigationController?.popViewController(animated: true)
            }
            
            tableView.setEditing(false, animated: true)
            navigationItem.rightBarButtonItem?.title = "Select"
            navigationItem.leftBarButtonItem = nil
        } else {
            // When 'Select' is tapped, enter editing mode
            tableView.setEditing(true, animated: true)
            navigationItem.rightBarButtonItem?.title = "Done"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEditingMode))
        }
    }

    /// Cancels the table view's editing mode, reverting any changes made
    @objc func cancelEditingMode() {
        tableView.setEditing(false, animated: true)
        navigationItem.rightBarButtonItem?.title = "Select"
        navigationItem.leftBarButtonItem = nil
        tableView.reloadData()
    }

    // MARK: - Table view data source
    /// Returns the number of sections in the table view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// Returns the number of locations in the itinerary.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedLocations.count
    }

    /// Returns a cell with the appropriate location data for the specified row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
        let location = savedLocations[indexPath.row]
        
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = location.address

        return cell
    }

    /// Returns whether the specified row can be edited.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Deletes a specified location from the saved locations.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.databaseController?.unsaveLocation(location: savedLocations[indexPath.row])
        }
    }
    /// Adds the selected location to the itinerary.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
            let location = savedLocations[indexPath.row]
            let _ = databaseController?.addLocationToPlan(location: location, plan: plan!)
            navigationController?.popViewController(animated: true)
        }
    }

}
