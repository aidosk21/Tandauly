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
    var mapVCDelegate : MapVCDelegate?
    var place = Place()
    let identifier = "identifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 1000.0
    var segueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        currentAddressLabel.text = ""
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = nil
        setupMapView()
        checkLocationServices()
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        mapVCDelegate?.getAddress(address: currentAddressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func navigatorTapped() {
        showUserLocation()
    }
    
    @IBAction func goDirButtonTapped() {
        goDirection()
    }
    private func setupMapView() {
        goDirectionButton.isHidden = true
        if segueIdentifier == "showPlace" {
            currentAddressLabel.isHidden = true
            doneButton.isHidden = true
            pinImage.isHidden = true
            goDirectionButton.isHidden = false
            setupPlacemark()
        }
        
    }
    
    private func setupPlacemark() {
        guard let location = place.location else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            guard let placemarks else { return }
            let placemark = placemarks.first
            let annotation = MKPointAnnotation()
            
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            self.placeCoordinate = placemarkLocation.coordinate
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    
    private func goDirection() {
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Ошибка", message: "Ваше местоположение не найдено")
            return
        }
        guard let request = createRequest(from: location)  else {
            showAlert(title: "Ошибка", message: "Место назначения не найдено")
            return
        }
        
         let directions = MKDirections(request: request)
        directions.calculate { responce, error in
            if let error { print(error) }
            guard let responce else {
                self.showAlert(title: "Ошибка", message: "Место назначения недоступно")
                return
            }
            for route in responce.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime
            }
        }
            
        
    }
    
    private func createRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }
        
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthStatus()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Службы геолокации отключены",
                               message: "Включите в настройках службы геолокации")
            }
        }
        
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func checkLocationAuthStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways: break
        case .authorizedWhenInUse: mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation() }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Службы геолокации отключены",
                               message: "Дайте Tandauly разрешение в настройках чтобы определить вашу геолокацию")
            }
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
            break
        case .restricted: break
        @unknown default: break
        }
    }
    
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func getLocationFromPin(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(settingsUrl! as URL, options: [:], completionHandler: nil) }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        present(alertController, animated: true)
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
        let center = getLocationFromPin(for: mapView)
        let geocoder = CLGeocoder()
        
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
        checkLocationAuthStatus()
    }
}
