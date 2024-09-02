//
//  LocationMapViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 8/6/2024.
//

import UIKit
import MapKit

class LocationMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var locationMapView: MKMapView!
    
    var location: LocationData?
    var nearbyHotels: [LocationData] = []
    var nearbyRestaurants: [LocationData] = []
    var nearbyActivities: [LocationData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMapView.delegate = self
                
        setupMapView()
    }
    
    /// Sets up the map view with annotations for the main location and nearby places.
    func setupMapView() {
        guard let location = location else { return }
        
        // Add annotation for the selected location
        let mainAnnotation = CustomAnnotation()
        mainAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(location.latitude)!, longitude: Double(location.longitude)!)
        mainAnnotation.title = location.name
        mainAnnotation.annotationType = .lodging
        locationMapView.addAnnotation(mainAnnotation)
        locationMapView.selectAnnotation(mainAnnotation, animated: true)
        
        // Set the region to center on the main location annotation
        let region = MKCoordinateRegion(center: mainAnnotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        locationMapView.setRegion(region, animated: true)
        
        // Add annotations for nearby hotels
        for hotel in nearbyHotels {
            let annotation = CustomAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(hotel.latitude)!, longitude: Double(hotel.longitude)!)
            annotation.title = hotel.name
            annotation.annotationType = .lodging
            locationMapView.addAnnotation(annotation)
        }
        
        // Add annotations for nearby restaurants
        for restaurant in nearbyRestaurants {
            let annotation = CustomAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(restaurant.latitude)!, longitude: Double(restaurant.longitude)!)
            annotation.title = restaurant.name
            annotation.annotationType = .restaurant
            locationMapView.addAnnotation(annotation)
        }
        
        // Add annotations for nearby activities
        for activity in nearbyActivities {
            let annotation = CustomAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(activity.latitude)!, longitude: Double(activity.longitude)!)
            annotation.title = activity.name
            annotation.annotationType = .tourist_attraction
            locationMapView.addAnnotation(annotation)
        }
    }
    
    /// Customizes the appearance of annotations on the map.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
        
        let identifier = "CustomAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = customAnnotation
        }
        
        // Customize the annotation view based on the annotation type
        switch customAnnotation.annotationType {
        case .lodging:
            annotationView?.glyphImage = UIImage(systemName: "bed.double.fill")
            annotationView?.markerTintColor = .systemBlue
        case .restaurant:
            annotationView?.glyphImage = UIImage(systemName: "fork.knife")
            annotationView?.markerTintColor = .systemRed
        case .tourist_attraction:
            annotationView?.glyphImage = UIImage(systemName: "star.fill")
            annotationView?.markerTintColor = .systemYellow
        case .none:
            annotationView?.glyphImage = nil
        }
        
        return annotationView
    }
}

class CustomAnnotation: MKPointAnnotation {
    var annotationType: PlaceType?
}
