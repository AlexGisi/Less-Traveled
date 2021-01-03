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
    @IBOutlet weak var trackLabel: UILabel!
    private var currentLocation: CLLocation?
    
    private let location_manager = CLLocationManager()
    
    private var doPanToUser = true
    private var pastVisitedLocations: [CLLocation] = readVisitedLocations()
    private var justVisitedLocations: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.showsUserLocation = true
        map.showsTraffic = true
        attemptLocationAccess()
        startLocationAccess()
        
        enableTrackLabelTap()
        updateTrackLabelText()
    }
    
    public func saveUserData() {
        writeVisitedLocations(pastVisitedLocations, justVisitedLocations)
    }
    
    @objc private func trackLabelTapped(_ sender: UITapGestureRecognizer) {
        self.doPanToUser.toggle()
        self.updateTrackLabelText()
    }
    
    private func updateTrackLabelText() {
        if self.doPanToUser {
            self.trackLabel.text = "Tracking User"
        } else {
            self.trackLabel.text = "Not Tracking User"
        }
    }
    private func enableTrackLabelTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.trackLabelTapped(_:)))
        self.trackLabel.isUserInteractionEnabled = true
        self.trackLabel.addGestureRecognizer(tap)
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
        let alert = UIAlertController(title: "Incorrect Location Settings", message: "In order to use the app, precise and permanent location access must be granted.", preferredStyle: .alert)
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
            return
        default:
            recoverLocationAcces()
        }
        
        switch manager.accuracyAuthorization {
        case .fullAccuracy:
            return
        default:
            recoverLocationAcces()
        }
    }
    
    private func displayCurrentRegion() {
        if let location = self.currentLocation {
            let center = location.coordinate
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
            self.map.setRegion(region, animated: true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.doPanToUser = false
        updateTrackLabelText()
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkProperLocationAccess(manager)
        startLocationAccess()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.currentLocation = location
            if doPanToUser {
                displayCurrentRegion()
            }
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
    }
}
