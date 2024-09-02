//
//  PlanViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit

class PlanViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatabaseListener {
    
    @IBOutlet weak var plansTableView: UITableView!
    
    let SECTION_ONGOING = 0
    let SECTION_UPCOMING = 1
    let SECTION_COMPLETED = 2
    let CELL_PLAN = "planCell"
    var plans = [Plan]()
    var ongoingPlans = [Plan]()
    var upcomingPlans = [Plan]()
    var completedPlans = [Plan]()
    
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .plan
    
    func onPlanListChange(change: DatabaseChange, planList: [Plan]) {
        plans = planList
        categorisePlans()
        plansTableView.reloadData()
    }
    
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location]) {
        // Do nothing
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Set the dataSource and delegate for the tableView
        plansTableView.dataSource = self
        plansTableView.delegate = self
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
    
    /// Returns the number of sections in the table view.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    /// Returns the number of rows (plans) in the specified section of the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_ONGOING:
            return ongoingPlans.count
        case SECTION_UPCOMING:
            return upcomingPlans.count
        case SECTION_COMPLETED:
            return completedPlans.count
        default:
            return 0
        }
    }
    
    /// Returns a cell to insert in a particular location of the table view.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PLAN, for: indexPath)
        let plan: Plan
        
        // Determine the plan based on the section
        if indexPath.section == SECTION_ONGOING {
            plan = ongoingPlans[indexPath.row]
        }
        else if indexPath.section == SECTION_UPCOMING {
            plan = upcomingPlans[indexPath.row]
        }
        else {
            plan = completedPlans[indexPath.row]
        }
        
        // Set the plan name as the title
        cell.textLabel?.text = plan.name
        
        // Set the plan start date as the subtitle
        if let startDate = plan.start {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            cell.detailTextLabel?.text = dateFormatter.string(from: startDate)
        }
        return cell
    }
    
    /// Returns whether a given row can be edited.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    /// Deletes a specified row (plan) in the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the plan from the core data
            self.databaseController?.deletePlan(plan: plans[indexPath.row])
        }
    }
    
    /// Returns the title of the header for the specified section of the table view.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_ONGOING:
            return "Ongoing"
        case SECTION_UPCOMING:
            return "Upcoming"
        case SECTION_COMPLETED:
            return "Completed"
        default:
            return nil
        }
    }
    
    /// Categorises plans into ongoing, upcoming, and completed plans based on their start and end dates relative to the current date.
    private func categorisePlans() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Get the start of the current day
        let currentStartOfDay = calendar.startOfDay(for: currentDate)
        
        // Filter and sort ongoing plans
        ongoingPlans = plans.filter { plan in
            guard let startDate = plan.start, let endDate = plan.end else { return false }
            let startOfDay = calendar.startOfDay(for: startDate)
            let endOfDay = calendar.startOfDay(for: endDate)
            return startOfDay <= currentStartOfDay && endOfDay >= currentStartOfDay
        }.sorted(by: { $0.start! < $1.start! })
        
        // Filter and sort upcoming plans
        upcomingPlans = plans.filter { plan in
            guard let startDate = plan.start else { return false }
            let startOfDay = calendar.startOfDay(for: startDate)
            return startOfDay > currentStartOfDay
        }.sorted(by: { $0.start! < $1.start! })
        
        // Filter and sort completed plans
        completedPlans = plans.filter { plan in
            guard let endDate = plan.end else { return false }
            let endOfDay = calendar.startOfDay(for: endDate)
            return endOfDay < currentStartOfDay
        }.sorted(by: { $0.start! < $1.start! })
    }
    
    // MARK: - Navigation
    /// Prepares for a segue to the ItineraryTableViewController by passing the selected plan.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPlanSegue" {
            if let destination = segue.destination as? ItineraryTableViewController,
               let indexPath = plansTableView.indexPathForSelectedRow {
                // Determine the selected plan based on the section
                let selectedPlan: Plan
                switch indexPath.section {
                case SECTION_ONGOING:
                    selectedPlan = ongoingPlans[indexPath.row]
                case SECTION_UPCOMING:
                    selectedPlan = upcomingPlans[indexPath.row]
                case SECTION_COMPLETED:
                    selectedPlan = completedPlans[indexPath.row]
                default:
                    return
                }
                
                // Pass the data to the destination view controller
                destination.plan = selectedPlan
            }
        }
    }

}
