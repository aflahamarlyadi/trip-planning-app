//
//  ProfileViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit
import MapKit

class ProfileViewController: UIViewController, MKMapViewDelegate, DatabaseListener {

    @IBOutlet weak var footprintMapView: MKMapView!
    
    var savedLocations = [Location]()
    weak var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .location
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        setupMapView()
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

    /// Sets up the map view with delegate and gesture recognizer configurations.
    func setupMapView() {
        footprintMapView.delegate = self

        // Make the map non-interactive
        footprintMapView.isScrollEnabled = false
        footprintMapView.isZoomEnabled = false
        footprintMapView.isPitchEnabled = false
        footprintMapView.isRotateEnabled = false

        // Add tap gesture recognizer to the map view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        footprintMapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// Handles the tap gesture on the map view by performing a segue to the full map view.
    @objc func mapViewTapped() {
        performSegue(withIdentifier: "showFootprintSegue", sender: self)
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
        
        // Set the map view's region to center on the last saved location
        if let lastLocation = savedLocations.last {
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude), latitudinalMeters: 10000, longitudinalMeters: 10000)
            footprintMapView.setRegion(region, animated: true)
        }
    }

    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
     */
}


