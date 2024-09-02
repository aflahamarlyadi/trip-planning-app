//
//  TabBarController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 22/5/2024.
//

import UIKit

class TabBarController: UITabBarController {
    
//    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if let databaseController, databaseController.activeUser() == false {
            performSegue(withIdentifier: "showLoginSegue", sender: self)
        }
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
