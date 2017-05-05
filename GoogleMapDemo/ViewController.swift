//
//  ViewController.swift
//  GoogleMapDemo
//
//  Created by vishalsonawane on 04/05/17.
//  Copyright © 2017 vishalsonawane. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController,CLLocationManagerDelegate{
    @IBOutlet weak var buttonGetYourLocation: UIButton!
    @IBOutlet weak var labelTotalDistance: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    @IBOutlet weak var destinationLocationStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var yourLocationStackViewHeightConstraint: NSLayoutConstraint!
    var locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    
    @IBOutlet weak var labelAdressLine1: UILabel!
    
    @IBOutlet weak var labelAdressLine2: UILabel!
    // Declare variables to hold address form values.
    var street_number: String = ""
    var route: String = ""
    var neighborhood: String = ""
    var locality: String = ""
    var administrative_area_level_1: String = ""
    var country: String = ""
    var postal_code: String = ""
    var postal_code_suffix: String = ""
  
    
    func showInternetNotAvailableError() {
        let alertController = UIAlertController(title: "🚫ERROR🚫", message: "Please check your internet conection.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        labelTotalDistance.text = ""
        labelTotalDistance.isHidden = true
        placesClient = GMSPlacesClient.shared()
        yourLocationStackViewHeightConstraint.constant = 0
        destinationLocationStackViewHeightConstraint.constant = 0
        self.buttonGetYourLocation.setTitle("Get your location", for: .normal)
    }
    
    // Present the Autocomplete view controller when the user taps the search field.
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        
        //show error if internet is not available
        if NSObject.currentReachabilityStatus == .notReachable {
            showInternetNotAvailableError()
            return
        }
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Set a filter to return only addresses.
        let addressFilter = GMSAutocompleteFilter()
        addressFilter.type = .address
        autocompleteController.autocompleteFilter = addressFilter
        
        present(autocompleteController, animated: true, completion: nil)
    }
      

    // Populate the address form fields.
    func fillAddressForm() {
        labelAdressLine1.text = street_number + " " + route + " " + locality
       var postalCode = ""
        if postal_code_suffix != "" {
            postalCode = postal_code + "-" + postal_code_suffix
        } else {
            postalCode = postal_code
        }
        labelAdressLine2.text = administrative_area_level_1 + " " + country + " " + postalCode
        
        // Clear values for next time.
        street_number = ""
        route = ""
        neighborhood = ""
        locality = ""
        administrative_area_level_1  = ""
        country = ""
        postal_code = ""
        postal_code_suffix = ""
    }

    
    override func loadView() {
        super.loadView()
        
        //show my location
        self.mapView.isMyLocationEnabled = true
        
       // Location Manager code to fetch current location
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
    }
    
    //Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        mapView.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
       
        
    }
   
    
    // Get your current location address
    @IBAction func getCurrentPlace(_ sender: UIButton) {
        
        //show error if internet is not available
        if NSObject.currentReachabilityStatus == .notReachable {
            showInternetNotAvailableError()
            return
        }
        
        buttonGetYourLocation.setTitle("Fetching location...", for: .normal)
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            self.nameLabel.text = "No current place"
            self.addressLabel.text = ""
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.buttonGetYourLocation.setTitle("Get your location", for: .normal)
                     self.yourLocationStackViewHeightConstraint.constant = 50
                    self.nameLabel.text = place.name
                    self.addressLabel.text = place.formattedAddress?.components(separatedBy: ", ")
                        .joined(separator: "\n")
                }
            }
        })
    }
      
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        // Print place info to the console.
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        
        // Get the address components.
        if let addressLines = place.addressComponents {
            // Populate all of the address fields we can find.
            for field in addressLines {
                switch field.type {
                case kGMSPlaceTypeStreetNumber:
                    street_number = field.name
                case kGMSPlaceTypeRoute:
                    route = field.name
                case kGMSPlaceTypeNeighborhood:
                    neighborhood = field.name
                case kGMSPlaceTypeLocality:
                    locality = field.name
                case kGMSPlaceTypeAdministrativeAreaLevel1:
                    administrative_area_level_1 = field.name
                case kGMSPlaceTypeCountry:
                    country = field.name
                case kGMSPlaceTypePostalCode:
                    postal_code = field.name
                case kGMSPlaceTypePostalCodeSuffix:
                    postal_code_suffix = field.name
                // Print the items we aren't using.
                default:
                    print("Type: \(field.type), Name: \(field.name)")
                }
            }
        }
        
        // Call custom function to populate the address form.
        fillAddressForm()
         destinationLocationStackViewHeightConstraint.constant = 50
        // Close the autocomplete widget.
        self.dismiss(animated: true, completion: nil)
        
        
        //Calculate distance between source and destination
        let loc1 = self.mapView.myLocation
        let loc2 = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let distance = (loc1?.distance(from: loc2))! / 1000.0 //convert into km
        print("DISTANCE = \(String(describing: distance))")
       
        labelTotalDistance.isHidden = false
        labelTotalDistance.text = String(format: "Total Distance: %.2f KM",distance)
        
        let loc11 = CLLocationCoordinate2D(latitude: (loc1?.coordinate.latitude)!, longitude: (loc1?.coordinate.longitude)!)
        let loc22 = CLLocationCoordinate2D(latitude: loc2.coordinate.latitude, longitude: loc2.coordinate.longitude)
        
        //Draw route
        getPolylineRoute(from: loc11, to: loc22)

        //Put marker for destination
        let marker = GMSMarker()
        marker.position = loc22
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = mapView
        
        //zoom to proper region so that sourc and destination will be visible properly
        var region:GMSVisibleRegion = GMSVisibleRegion()
        region.nearLeft = CLLocationCoordinate2DMake((loc1?.coordinate.latitude)!, (loc1?.coordinate.longitude)!)
        region.farRight = CLLocationCoordinate2DMake(loc2.coordinate.latitude,loc2.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: region.nearLeft,coordinate: region.farRight)
        let camera = self.mapView.camera(for:bounds, insets:UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
       
        mapView.camera = camera!;
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
extension ViewController{
    
    // Pass your source and destination coordinates in this method.
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
       
        //show error if internet is not available
        if NSObject.currentReachabilityStatus == .notReachable {
            showInternetNotAvailableError()
            return
        }
        
        //clear all previous markers and routes if any
        mapView.clear()
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let url = URL(string: "http://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&alternatives=true")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        print(json)
                        let routes = json["routes"] as? [Any]
                        
                        for  index in (0..<routes!.count){
                            let overview_polyline = routes?[index] as?[String:Any]
                            let overview_polyline1 = overview_polyline?["overview_polyline"] as?[String:Any]
                            let polyString = overview_polyline1?["points"] as? String
                           
                            var linecolor = UIColor.blue
                            if index != 0{
                                linecolor = UIColor.darkGray
                            }
                            
                            //Call this method to draw path on map
                            self.showPath(polyStr: polyString!,lineColor:linecolor)
                        }
                        
                    }
                    
                }catch{
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String,lineColor:UIColor){
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.strokeColor = lineColor
        polyline.map = self.mapView
    }
}


