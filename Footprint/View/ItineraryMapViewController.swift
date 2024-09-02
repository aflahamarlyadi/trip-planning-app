//
//  ItineraryMapViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit
import MapKit
import CoreLocation

class ItineraryMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var itineraryMapView: MKMapView!
    
    var plan: Plan?
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = plan?.name
        
        itineraryMapView.delegate = self
        itineraryMapView.showsUserLocation = true
        itineraryMapView.userTrackingMode = .follow
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        setupMapView()
    }
    
    /// Configures the map view to display annotations for all locations in the plan's itinerary.
    func setupMapView() {
        guard let itinerary = plan?.itinerary else { return }
        
        var annotations: [MKAnnotation] = []
        
        // Create annotations for each location in the itinerary
        for location in itinerary {
            if let location = location as? Location {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                annotation.title = location.name
                annotations.append(annotation)
            }
        }
        
        // Add all annotations to the map view
        itineraryMapView.addAnnotations(annotations)
    }
    
    // MARK: - CLLocationManagerDelegate
    /// Updates the user's location on the map view and centers the map view around the user's current location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            // Update the user's current location
            currentLocation = userLocation
            
            // Define the region to be displayed on the map view, centered on the user's location
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            // Set the map view's region to the defined region
            itineraryMapView.setRegion(region, animated: true)
            
            // Set up the map view with the annotations for the plan's itinerary
            setupMapView()
        }
    }
    
    /// Handles errors that occur when attempting to retrieve the user's location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    // MARK: - MKMapViewDelegate
    /// Returns a view for the specified annotation object.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "LocationAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}
