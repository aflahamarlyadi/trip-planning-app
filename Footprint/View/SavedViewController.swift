//
//  SavedViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit

class SavedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatabaseListener {

    let CELL_LOCATION = "savedLocationCell"
    var savedLocations = [Location]()
    
    @IBOutlet weak var savedTableView: UITableView!
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .location
    
    func onPlanListChange(change: DatabaseChange, planList: [Plan]) {
        // Do nothing
    }
    
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location]) {
        savedLocations = savedLocationsList
        savedTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        savedTableView.dataSource = self
        savedTableView.delegate = self
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

    // MARK: - Table view data source
    /// Returns the number of sections in the table view.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// Returns the number of saved locations.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedLocations.count
    }

    /// Returns a cell with the appropriate location data for the specified row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
        let location = savedLocations[indexPath.row]
        
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = location.address

        return cell
    }

    /// Returns whether the specified row can be edited.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Deletes a specified location from the saved locations.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.databaseController?.unsaveLocation(location: savedLocations[indexPath.row])
        }
    }

}
