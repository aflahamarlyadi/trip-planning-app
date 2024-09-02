//
//  FootprintViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit
import MapKit

class FootprintViewController: UIViewController, MKMapViewDelegate, DatabaseListener {
    
    @IBOutlet weak var footprintMapView: MKMapView!
    
    var savedLocations = [Location]()
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .location
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        footprintMapView.delegate = self
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
        // Do nothing
    }
    
    func onSavedLocationsListChange(change: DatabaseChange, savedLocationsList: [Location]) {
        savedLocations = savedLocationsList
        addAnnotations()
    }
    
    /// Adds annotations to the map view for all saved locations
    func addAnnotations() {
        // Remove existing annotations
        footprintMapView.removeAnnotations(footprintMapView.annotations)
        
        // Add annotations for each saved location
        for location in savedLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = location.name
            footprintMapView.addAnnotation(annotation)
        }
        
        // Set the map view's region to center on the first saved location
        if let firstAnnotation = footprintMapView.annotations.first {
            let region = MKCoordinateRegion(center: firstAnnotation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            footprintMapView.setRegion(region, animated: true)
        }
    }
    
}
