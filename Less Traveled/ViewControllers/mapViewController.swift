//
//  mapViewController.swift
//  Less Traveled
//
//  Created by Alex Gisi on 12/15/20.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    
    private let location_manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attemptLocationAccess()
        startLocationAccess()
    }
    
    private func attemptLocationAccess() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        location_manager.delegate = self
        location_manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        location_manager.requestAlwaysAuthorization()
        checkProperLocationAccess(location_manager)
    }
    
    private func startLocationAccess() {
        location_manager.startUpdatingLocation()
        location_manager.allowsBackgroundLocationUpdates = true
        location_manager.pausesLocationUpdatesAutomatically = true
    }
    
    private func recoverLocationAcces() {
        let alert = UIAlertController(title: "Precise Location Access Required", message: "In order to use the app, precise location access must be granted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = NSURL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url as URL)
            }
        })
        self.present(alert, animated: true)
    }
    
    private func checkProperLocationAccess(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Good.")
        default:
            print("recovering...")
            recoverLocationAcces()
        }
        
        switch manager.accuracyAuthorization {
        case .fullAccuracy:
            print("Accuracy good.")
        default:
            print("recovering for accuracy...")
            recoverLocationAcces()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkProperLocationAccess(manager)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
    }
}
