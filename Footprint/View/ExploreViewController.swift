//
//  ExploreViewController.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit
import CoreLocation

/// Enum to handle location request errors.
enum LocationRequestError: Error {
    case invalidImageURL
    case invalidServerResponse
}

class ExploreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var locationsTableView: UITableView!
    
    let CELL_LOCATION = "locationCell"
    let locationManager = CLLocationManager()
    var locationIDs = [String]()
    var locations = [LocationData]()
    var indicator = UIActivityIndicatorView()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the table view
        locationsTableView.dataSource = self
        locationsTableView.delegate = self
        
        // Setup the search controller, location manager, and activity indicator
        setupSearchController()
        setupLocationManager()
        setupActivityIndicator()
    }
    
    // MARK: - Setup Methods
    /// Sets up the search controller.
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a location"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    /// Sets up the location manager.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    /// Sets up the activity indicator.
    private func setupActivityIndicator() {
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }

    // MARK: - Delegates
    /// Notifies the delegate that new location data is available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // Extract the latitude and longitude from the last location update.
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            // Stop further location updates to save battery life.
            locationManager.stopUpdatingLocation()
            
            // Request nearby locations based on the updated coordinates.
            Task {
                await requestNearbyLocations(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    /// Called when the search bar ends editing and processes the search query.
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Ensure there's a valid search text before proceeding with the search query.
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        
        // Clear the current table view.
        locationIDs.removeAll()
        locations.removeAll()
        locationsTableView.reloadData()
        
        navigationItem.searchController?.dismiss(animated: true)
        
        // Request search locations based on the query.
        Task {
            await requestSearchLocations(query: searchText)
        }
    }
    
    /// Called when the cancel button is clicked in the search bar.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Get the user's current location if available.
        guard let currentLocation = locationManager.location else { return }
        
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        
        // Stop further location updates to save battery life.
        locationManager.stopUpdatingLocation()
        
        // Request nearby locations based on the current coordinates.
        Task {
            await requestNearbyLocations(latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - Table View Data Source
    /// Returns the number of sections in the table view.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Returns the number of rows (locations) in the specified section of the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    
    /// Returns the cell for a given row in the collection view.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath) as! LocationTableViewCell
        let location = locations[indexPath.row]
        
        // Ensure the image is blank after cell reuse
        cell.locationImageView?.image = nil
        
        // Set the image of the location if it exists
        if let image = location.image {
            cell.locationImageView?.image = image
        }
        // Otherwise, download it using the image URL
        else if location.imageIsDownloading == false, let imageURL = location.imageURL {
            let requestURL = URL(string: imageURL)
            // If the request URL is valid, create a new asynchronous task to download the image.
            if let requestURL {
                Task {
                    // Mark the image as being downloaded to prevent duplicate download attempts.
                    location.imageIsDownloading = true
                    
                    do {
                        // Attempt to download the image data from the URL.
                        let (data, response) = try await URLSession.shared.data(from: requestURL)
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            location.imageIsDownloading = false
                            throw LocationRequestError.invalidImageURL
                        }
                        
                        // If the image data is valid, set the downloaded image.
                        if let image = UIImage(data: data) {
                            print("Image downloaded: " + imageURL)
                            location.image = image
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                        // Otherwise, set a placeholder image.
                        else {
                            print("Image invalid: " + imageURL)
                            location.imageIsDownloading = false
                            location.image = UIImage(named: "PlaceholderImage")
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                    
                    // Handle any errors that occur during the image download.
                    catch {
                        print(error.localizedDescription)
                    }
                }
            }
            // Otherwise, print an error message.
            else {
                print("Error: URL not valid: " + imageURL)
            }
        }
        // If there is no image URL, set a placeholder image.
        else {
            cell.locationImageView?.image = UIImage(named: "PlaceholderImage")
        }
        
        // Set the name of the location
        cell.locationNameLabel?.text = location.name
        
        // Set the address of the location
        cell.locationAddressLabel?.text = location.address

        // Return the cell
        return cell
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

    /// Requests the searched location based on the given search query.
    /// - Parameter query: The search query.
    func requestSearchLocations(query: String) async {
        // Start the activity indicator to indicate that the search data is being requested.
        indicator.startAnimating()
        
        // Define the URL string for the Google Places Text Search API
        let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json"
        guard var components = URLComponents(string: urlString) else { return }

        // Load the API key from Config.plist
        let apiKey = loadAPIKey()
        
        // Add the query parameters to the URL
        let queryItems: [URLQueryItem] = [
            // The search query.
            URLQueryItem(name: "query", value: query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            // The API key.
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "language", value: "en")
        ]
        components.queryItems = queryItems
        
        // Ensure the URL is valid
        guard let url = components.url else {
            print("Invalid URL.")
            return
        }
        
        // Create the URL request
        let request = URLRequest(url: url)

        do {
            // Fetch the queried location
            let (data, _) = try await URLSession.shared.data(for: request)
            
            do {
                // Stop the activity indicator as the data has been fetched
                self.indicator.stopAnimating()
                
                // Decode the fetched data into NearbyLocationsData
                let decoder = JSONDecoder()
                let search = try decoder.decode(NearbyLocationsData.self, from: data)
                if let locations = search.results {
                    // Extract place IDs from the search results
                    self.locationIDs = locations.map { $0.place_id }
                    
                    // Iterate through each location ID to fetch detailed information
                    for locationID in self.locationIDs {
                        await self.requestLocationDetails(locationID)
                    }
                }
                
                // Reload the table view with the new data
                self.locationsTableView.reloadData()
            }
        } catch {
            // Print error if data fetch or decoding fails
            print("Failed to decode or fetch data: \(error)")
        }
    }

    /// Requests nearby locations based on the given latitude and longitude.
    /// - Parameters:
    ///   - latitude: The latitude coordinate to search nearby locations.
    ///   - longitude: The longitude coordinate to search nearby locations.
    func requestNearbyLocations(latitude: Double, longitude: Double) async {
        // Start the activity indicator to indicate that the nearby data is being requested.
        indicator.startAnimating()
        
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
            URLQueryItem(name: "type", value: "tourist_attraction"),
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
                self.indicator.stopAnimating()
                
                // Decode the fetched data into NearbyLocationsData
                let decoder = JSONDecoder()
                let nearbyLocationsData = try decoder.decode(NearbyLocationsData.self, from: data)
                if let locations = nearbyLocationsData.results {
                    // Extract place IDs from the search results
                    self.locationIDs = locations.map { $0.place_id }
                    
                    // Iterate through each nearby location ID to fetch detailed information
                    for locationID in self.locationIDs {
                        await self.requestLocationDetails(locationID)
                    }
                }
            }
        } catch {
            // Print error if data decoding fails
            print("Failed to decode or fetch data: \(error)")
        }
    }
    
    /// Requests the details and photo for a specific location based on the given ID.
    /// - Parameter locationID: The unique identifier of the location to fetch details for.
    func requestLocationDetails(_ locationID: String) async {
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
                
                // Add the location data to the list and reload the table view
                self.locations.append(locationData)
                self.locationsTableView.reloadData()
            }
        } catch {
            // Print error if data fetch or decoding fails
            print("Failed to decode or fetch data: \(error)")
        }
    }


    // MARK: - Navigation
    /// Prepares for a segue to the LocationViewVontroller by passing the selected location data.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationSegue" {
            if let destination = segue.destination as? LocationViewController, let indexPath = locationsTableView.indexPathForSelectedRow {
                // Get the selected location based on the selected row's index
                let selectedLocation = locations[indexPath.row]
                
                // Pass the selected location data to the destination view controller
                destination.location = selectedLocation
            }
        }
    }

}
