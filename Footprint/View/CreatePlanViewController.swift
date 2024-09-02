//
//  CreatePlanViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 15/5/2024.
//

import UIKit

class CreatePlanViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    /// Handles the action of creating a new plan.
    @IBAction func createPlan(_ sender: Any) {
        // Check if the name field is empty
        guard let name = nameTextField.text, !name.isEmpty else {
            displayMessage(title: "Error", message: "A name is required.")
            return
        }

        let start = startDatePicker.date
        let end = endDatePicker.date
        let currentDate = Calendar.current.startOfDay(for: Date())
        
        // Check if the start date is today or in the future
        if start < currentDate {
            displayMessage(title: "Error", message: "The start date must be today or a future date.")
            return
        }
        
        // Check if the end date is before the start date
        if end < start {
            displayMessage(title: "Error", message: "The end date cannot be before the start date.")
            return
        }

        // If all checks pass, add the plan to the core data
        let _ = databaseController?.addPlan(name: name, start: start, end: end)
        navigationController?.popViewController(animated: true)
    }
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    /// Displays an alert message with the given title and message.
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

}
