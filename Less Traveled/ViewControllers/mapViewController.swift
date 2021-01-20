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
    @IBOutlet weak var trackImage: UIImageView!
    @IBOutlet weak var driveButton: UIButton!
    private var currentLocation: CLLocation?
    
    private let location_manager = CLLocationManager()
    
    private var doPanToUser = true
    private var driving = false
    
    private var pastDrives: [[CLLocation]] = readDrives()
    private var currentDrive: [CLLocation] = []
    private var pastVisitedOverlays: [MKPolyline] = []
    private var justVisitedOverlay: MKPolyline = MKPolyline()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map.delegate = self
        
        self.pastVisitedOverlays = getPastVisitedOverlays(self.pastDrives)
        self.showPastVisitedOverlays()
        self.map.addOverlay(justVisitedOverlay)
        
        map.showsUserLocation = true
        map.showsTraffic = true
        
        attemptLocationSetup()
        startLocationAccess()
        
        enableUIGestures()
        updateTrackLabelImage()
    }
    
    public func addLocation(_ location: CLLocation) {
        self.currentDrive.append(location)
        saveUserData()
    }
    
    public func saveUserData() {
        writeDrives(self.pastDrives)
    }
    
    public func startDrive() {
        self.driving = true
        self.driveButton.setTitle("End Drive", for: .normal)
    }
    
    public func endDrive() {
        self.driving = false
        self.pastDrives.append(self.currentDrive)
        self.currentDrive.removeAll()
        saveUserData()
        self.driveButton.setTitle("Start Drive", for: .normal)
    }
    
    private func showPastVisitedOverlays() {
        map.addOverlays(self.pastVisitedOverlays)
    }
    
    private func updateJustVisitedOverlay() {
        map.removeOverlay(self.justVisitedOverlay)
        var justVisitedCoords: [CLLocationCoordinate2D] = self.currentDrive.map {$0.coordinate}
        self.justVisitedOverlay = MKPolyline(coordinates: &justVisitedCoords, count: justVisitedCoords.count)
        map.addOverlay(self.justVisitedOverlay)
    }
    
    @objc private func trackLabelTapped(_ sender: UITapGestureRecognizer) {
        self.doPanToUser.toggle()
        self.updateTrackLabelImage()
    }
    
    @objc private func driveButtonTapped(_ sender: UITapGestureRecognizer) {
        if self.driving {
            endDrive()
        } else {
            startDrive()
        }
    }
    
    private func updateTrackLabelImage() {
        if self.doPanToUser {
            self.trackImage.image = UIImage(systemName: "paperplane.circle.fill")
        } else {
            self.trackImage.image = UIImage(systemName: "paperplane.circle")
        }
    }
    private func enableUIGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.trackLabelTapped(_:)))
        self.trackImage.isUserInteractionEnabled = true
        self.trackImage.addGestureRecognizer(tap)
        
        let driveTap = UITapGestureRecognizer(target: self, action: #selector(self.driveButtonTapped(_:)))
        self.driveButton.isUserInteractionEnabled = true
        self.driveButton.addGestureRecognizer(driveTap)
    }
    
    private func attemptLocationSetup() {
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
        if !hasProperLocationAccess(location_manager) {
            recoverLocationAcces()
        }
    }
    
    private func hasProperLocationAccess(_ manager: CLLocationManager) -> Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            switch manager.accuracyAuthorization {
            case .fullAccuracy:
                return true
            default:
                return false
            }
        default:
            return false
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
        updateTrackLabelImage()
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
            if self.driving && !location.wasVisited(checkedAgainst: Array(self.pastDrives.joined())) {
                self.addLocation(location)
                self.updateJustVisitedOverlay()
            }
        }
        if doPanToUser {
            displayCurrentRegion()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.black
        renderer.lineWidth = 3
        return renderer
    }
}
