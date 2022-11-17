//
//  MapManager.swift
//  Tandauly
//
//  Created by Aidos on 17.11.2022.
//

import UIKit
import MapKit

class MapManager {
    let locationManager = CLLocationManager()
    
    private let regionInMeters = 1000.0
    private var directionsArr: [MKDirections] = []
    private var placeCoordinate: CLLocationCoordinate2D?
    
    
    
     func setupPlacemark(place: Place, mapView: MKMapView) {
        guard let location = place.location else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            guard let placemarks else { return }
            let placemark = placemarks.first
            let annotation = MKPointAnnotation()
            
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            self.placeCoordinate = placemarkLocation.coordinate
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
     func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthStatus(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Службы геолокации отключены",
                               message: "Включите в настройках службы геолокации")
            }
        }
        
    }
    
     func checkLocationAuthStatus(mapView: MKMapView, segueIdentifier: String) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways: break
        case .authorizedWhenInUse: mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
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
    
     func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
     func goDirection(for mapView: MKMapView, previousLocation: (CLLocation) -> () ) {
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Ошибка", message: "Ваше местоположение не найдено")
            return 
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createRequest(from: location)  else {
            showAlert(title: "Ошибка", message: "Место назначения не найдено")
            return
        }
        
         let directions = MKDirections(request: request)
        resetMapView(withNew: directions, mapView: mapView)
        
        directions.calculate { responce, error in
            if let error { print(error) }
            guard let responce else {
                self.showAlert(title: "Ошибка", message: "Место назначения недоступно")
                return
            }
            for route in responce.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
//                let distance = String(format: "%.1f", route.distance / 1000)
//                let timeInterval = route.expectedTravelTime
            }
        }
    }
    
    
     func createRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
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
    
     func startTrackingUserLocation(for mapView: MKMapView, location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location else { return }
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else { return }
        
        closure(center)
    }
    
     func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        directionsArr.append(directions)
        let _ = directionsArr.map { $0.cancel() }
        directionsArr.removeAll()
        
    }
    
     func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(settingsUrl! as URL, options: [:], completionHandler: nil) }
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    }
    
}
