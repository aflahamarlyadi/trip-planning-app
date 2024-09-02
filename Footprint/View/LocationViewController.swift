//
//  LocationViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 26/4/2024.
//

import UIKit
import MapKit

enum PlaceType: String {
    case lodging
    case restaurant
    case tourist_attraction
}

class LocationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    @IBOutlet weak var locationDescriptionLabel: UILabel!
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var hotelsCollectionView: UICollectionView!
    @IBOutlet weak var restaurantsCollectionView: UICollectionView!
    @IBOutlet weak var activitiesCollectionView: UICollectionView!
    
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBAction func toggleBookmark(_ sender: Any) {
        guard let location = location else { return }
        
        if let locationData = databaseController?.fetchLocation(locationData: location) {
            let _ = databaseController?.unsaveLocation(location: locationData)
            bookmarkButton.image = UIImage(systemName: "bookmark")
        } else {
            let _ = databaseController?.saveLocation(locationData: location)
            bookmarkButton.image = UIImage(systemName: "bookmark.fill")
        }
    }
    
    let CELL_HOTEL = "hotelCell"
    let CELL_RESTAURANT = "restaurantCell"
    let CELL_ACTIVITY = "activityCell"
    
    var location: LocationData?
    
    weak var databaseController: DatabaseProtocol?
    
    var hotelIDs: [String] = []
    var hotels: [LocationData] = []
    var restaurantIDs: [String] = []
    var restaurants: [LocationData] = []
    var activityIDs: [String] = []
    var activities: [LocationData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the data source and delegate for the hotels, restaurants, and activities collection views.
        hotelsCollectionView.dataSource = self
        hotelsCollectionView.delegate = self
        restaurantsCollectionView.dataSource = self
        restaurantsCollectionView.delegate = self
        activitiesCollectionView.dataSource = self
        activitiesCollectionView.delegate = self
        
        // Initialize the database controller.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set up the UI elements with the location details.
        guard let location = location else { return }
        self.title = location.name
        locationImageView.image = location.image
        locationNameLabel.text = location.name
        locationAddressLabel.text = location.address
        locationDescriptionLabel.text = location.desc
        
        // Set the bookmark icon based on whether the location is saved in the database.
        if let _ = databaseController?.fetchLocation(locationData: location) {
            bookmarkButton.image = UIImage(systemName: "bookmark.fill")
        } else {
            bookmarkButton.image = UIImage(systemName: "bookmark")
        }
        
        // Set up the map view with location data.
        setupMapView()
        
        // Fetch nearby hotels asynchronously.
        Task {
            await requestNearbyLocations(latitude: Double(location.latitude)!, longitude: Double(location.longitude)!, type: .lodging)
        }
        // Fetch nearby restaurants asynchronously.
        Task {
            await requestNearbyLocations(latitude: Double(location.latitude)!, longitude: Double(location.longitude)!, type: .restaurant)
        }
        // Fetch nearby activities asynchronously.
        Task {
            await requestNearbyLocations(latitude: Double(location.latitude)!, longitude: Double(location.longitude)!, type: .tourist_attraction)
        }
    }
    
    /// Sets up the map view with an annotation at the location's coordinates.
    func setupMapView() {
        guard let location = location else { return }
        
        // Create an annotation with the location's coordinates and title.
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(location.latitude)!, longitude: Double(location.longitude)!)
        annotation.title = location.name
        locationMapView.addAnnotation(annotation)
        
        // Set the map's region to center on the annotation.
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        locationMapView.setRegion(region, animated: true)
        
        // Disable user interactions with the map.
        locationMapView.isScrollEnabled = false
        locationMapView.isZoomEnabled = false
        locationMapView.isPitchEnabled = false
        locationMapView.isRotateEnabled = false
        
        // Add a tap gesture recognizer to the map view to trigger a segue.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        locationMapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // Add a tap gesture recognizer to the map view to trigger a segue.
    @objc func mapViewTapped() {
        performSegue(withIdentifier: "showLocationMapSegue", sender: self)
    }
    
    // MARK: - Collection View Data Source
    /// Returns the number of items in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case hotelsCollectionView:
            return hotels.count
        case restaurantsCollectionView:
            return restaurants.count
        case activitiesCollectionView:
            return activities.count
        default:
            return 0
        }
    }
    
    /// Returns the cell for a given item in the collection view.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String
        let location: LocationData
        
        // Determine the cell identifier and location data based on the collection view
        switch collectionView {
        case hotelsCollectionView:
            cellIdentifier = CELL_HOTEL
            location = hotels[indexPath.row]
        case restaurantsCollectionView:
            cellIdentifier = CELL_RESTAURANT
            location = restaurants[indexPath.row]
        case activitiesCollectionView:
            cellIdentifier = CELL_ACTIVITY
            location = activities[indexPath.row]
        default:
            fatalError("Unexpected collection view")
        }
        
        // Dequeue the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! LocationCollectionViewCell

        // Ensure the image is blank after cell reuse
        cell.locationImageView?.image = nil

        // Set the image if it exists, otherwise download it
        if let image = location.image {
            cell.locationImageView?.image = image
        } else if location.imageIsDownloading == false, let imageURL = location.imageURL {
            let requestURL = URL(string: imageURL)
            if let requestURL {
                Task {
                    location.imageIsDownloading = true
                    do {
                        let (data, response) = try await URLSession.shared.data(from: requestURL)
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            location.imageIsDownloading = false
                            throw LocationRequestError.invalidImageURL
                        }
                        
                        if let image = UIImage(data: data) {
                            print("Image downloaded: " + imageURL)
                            location.image = image
                            collectionView.reloadItems(at: [indexPath])
                        } else {
                            print("Image invalid: " + imageURL)
                            location.imageIsDownloading = false
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("Error: URL not valid: " + imageURL)
            }
        } else {
            cell.locationImageView?.image = UIImage(named: "PlaceholderImage")
        }

        // Set the name of the location
        cell.locationNameLabel?.text = location.name

        return cell
    }

    /// Handles the selection of an item in the collection view.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Determine the selected location based on the collection view
        let selectedLocation: LocationData
        switch collectionView {
        case hotelsCollectionView:
            selectedLocation = hotels[indexPath.row]
        case restaurantsCollectionView:
            selectedLocation = restaurants[indexPath.row]
        case activitiesCollectionView:
            selectedLocation = activities[indexPath.row]
        default:
            return
        }
        
        // Create another instance of the LocationViewController
        if let locationVC = storyboard?.instantiateViewController(withIdentifier: "LocationViewController") as? LocationViewController {
            // Pass the selected location to the instance of the LocationViewController
            locationVC.location = selectedLocation
            
            // Push the LocationViewController onto the navigation stack
            navigationController?.pushViewController(locationVC, animated: true)
        }
    }
    
    // MARK: - API Requests
    // Function to load the API key from Config.plist
    func loadAPIKey() -> String {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
        let config = NSDictionary(contentsOfFile: path) as? [String: Any],
        let apiKey = config["API_KEY"] as? String {
            return apiKey
        }
        return ""
    }
    
    /// Requests nearby locations based on the given latitude and longitude.
    /// - Parameters:
    ///   - latitude: The latitude coordinate to search nearby locations.
    ///   - longitude: The longitude coordinate to search nearby locations.
    func requestNearbyLocations(latitude: Double, longitude: Double, type: PlaceType) async {
        // Define the URL string for the Google Places Nearby Search API
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        guard var components = URLComponents(string: urlString) else { return }

        // Load the API key from Config.plist
        let apiKey = loadAPIKey()
        
        // Add the query parameters to the URL
        let queryItems: [URLQueryItem] = [
            // The point around which to retrieve nearby locations.
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            // Restricts the results to places within the specified radius.
            URLQueryItem(name: "radius", value: "1000"),
            // Restricts the results to places matching the specified type.
            URLQueryItem(name: "type", value: type.rawValue),
            // The API key.
            URLQueryItem(name: "key", value: apiKey)
        ]
        components.queryItems = queryItems
        
        // Ensure the URL is valid
        guard let requestURL = components.url else {
            print("Invalid URL.")
            return
        }
        
        // Create the URL request
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Fetch nearby locations
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            do {
                // Stop the activity indicator as the data has been fetched
                let decoder = JSONDecoder()
                
                // Decode the fetched data into NearbyLocationsData
                let nearbyLocationsData = try decoder.decode(NearbyLocationsData.self, from: data)
                if let locations = nearbyLocationsData.results {
                    // Extract place IDs from the search results
                    let locationIDs = locations.map { $0.place_id }
                    
                    // Iterate through each nearby location ID to fetch detailed information
                    for locationID in locationIDs {
                        await requestLocationDetails(locationID, type: type)
                    }
                }
            }
        } catch {
            // Print error if data fetch or decoding fails
            print("Failed to decode or fetch data: \(error)")
        }
    }

    /// Requests detailed information and photos for a specific location based on the given ID.
    /// - Parameters:
    ///   - locationID: The unique identifier of the location to fetch details for.
    ///   - type: The type of place (lodging, restaurant, tourist attraction) to categorize the location data.
    func requestLocationDetails(_ locationID: String, type: PlaceType) async {
        // Define the URL string for the Google Place Details API
        let detailsURL = "https://maps.googleapis.com/maps/api/place/details/json"
        guard var detailsComponents = URLComponents(string: detailsURL) else { return }
        
        // Load the API key from Config.plist
        let apiKey = loadAPIKey()

        // Add the query parameters to the URL
        let detailsQueryItems: [URLQueryItem] = [
            // The unique identifier of the place to fetch details for.
            URLQueryItem(name: "place_id", value: locationID),
            // The API key.
            URLQueryItem(name: "key", value: apiKey)
        ]
        detailsComponents.queryItems = detailsQueryItems
        
        // Ensure the URL is valid
        guard let detailsRequestURL = detailsComponents.url else {
            print("Invalid URL.")
            return
        }

        // Create the URL request for fetching details
        let detailsRequest = URLRequest(url: detailsRequestURL)
        
        do {
            let (detailsData, _) = try await URLSession.shared.data(for: detailsRequest)
            
            do {
                let decoder = JSONDecoder()
                let locationData = try decoder.decode(LocationData.self, from: detailsData)
                
                // Check if there is a photo reference to fetch the photo
                if let photoReference = locationData.imageURL {
                    // Define the URL string for the Google Place Photos API
                    let photosURL = "https://maps.googleapis.com/maps/api/place/photo"
                    guard var photosComponents = URLComponents(string: photosURL) else { return }

                    // Load the API key from Config.plist
                    let apiKey = loadAPIKey()
                    
                    // Add the query parameters to the URL
                    let photosQueryItems: [URLQueryItem] = [
                        // The photo reference of the image.
                        URLQueryItem(name: "photoreference", value: photoReference),
                        // The max width of the returned image.
                        URLQueryItem(name: "maxwidth", value: "400"),
                        // The API key.
                        URLQueryItem(name: "key", value: apiKey)
                    ]
                    photosComponents.queryItems = photosQueryItems
                    
                    // Ensure the URL is valid
                    guard let photosRequestURL = photosComponents.url else {
                        print("Invalid URL.")
                        return
                    }
                    
                    // Create the URL request for fetching the photo
                    let photosRequest = URLRequest(url: photosRequestURL)
                    let (photosData, _) = try await URLSession.shared.data(for: photosRequest)
                    
                    if let image = UIImage(data: photosData) {
                        // Save the image to the locationData property
                        locationData.image = image
                    }
                }
                
                // Add the location data to the corresponding list and reload the collection view
                switch type {
                case .lodging:
                    self.hotels.append(locationData)
                    self.hotelsCollectionView.reloadData()
                case .restaurant:
                    self.restaurants.append(locationData)
                    self.restaurantsCollectionView.reloadData()
                case .tourist_attraction:
                    self.activities.append(locationData)
                    self.activitiesCollectionView.reloadData()
                }
            }
        } catch {
            // Print error if data fetch or decoding fails
            print("Failed to decode or fetch data: \(error)")
        }
    }

    // MARK: - Navigation
    /// Prepares for a segue to the LocationMapViewController by passing the selected location and nearby places data.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationMapSegue", let destination = segue.destination as? LocationMapViewController {
            // Pass the selected location and nearby locations to the destination view controller
            destination.location = self.location
            destination.nearbyHotels = self.hotels
            destination.nearbyRestaurants = self.restaurants
            destination.nearbyActivities = self.activities
        }
    }

}
