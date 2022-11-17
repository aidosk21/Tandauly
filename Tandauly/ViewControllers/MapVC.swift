//
//  MapVC.swift
//  Tandauly
//
//  Created by Aidos on 11.11.2022.
//

import UIKit
import MapKit
import CoreLocation

protocol MapVCDelegate {
    func getAddress(address: String?)
}

class MapVC: UIViewController {
    
    @IBOutlet weak var goDirectionButton: UIButton!
    @IBOutlet weak var currentAddressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pinImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    let mapManager = MapManager()
    var mapVCDelegate : MapVCDelegate?
    var place = Place()
    let identifier = "identifier"
  
    var segueIdentifier = ""
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrackingUserLocation(for: mapView, location: previousLocation) { currentLocation in
                self.previousLocation = currentLocation
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        mapView.delegate = self
        currentAddressLabel.text = ""
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = nil
        setupMapView()
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        mapVCDelegate?.getAddress(address: currentAddressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func navigatorTapped() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func goDirButtonTapped() {
        mapManager.goDirection(for: mapView) { location in
            self.previousLocation = location
        }
    }
       
    private func setupMapView() {
        goDirectionButton.isHidden = true
        
        mapManager.checkLocationAuthStatus(mapView: mapView, segueIdentifier: identifier)
         
        if segueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView  )
            currentAddressLabel.isHidden = true
            doneButton.isHidden = true
            pinImage.isHidden = true
            goDirectionButton.isHidden = false
        
        }
        
    }
    
    
 
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        
        if let image = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: image)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if segueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView )
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            if let error {
                print(error)
            }
            let placemark = placemarks?.first
            let streetName = placemark?.thoroughfare
            let homeNumber = placemark?.subThoroughfare
            DispatchQueue.main.async {
                self.currentAddressLabel.text = "\(streetName ?? ""), \(homeNumber ?? "")"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        return renderer
    }
    
    
}

extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAuthStatus(mapView: mapView, segueIdentifier: identifier)
    }
}
