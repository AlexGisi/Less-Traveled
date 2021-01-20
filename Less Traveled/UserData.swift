//
//  UserData.swift
//  Less Traveled
//
//  Created by Alex Gisi on 12/22/20.
//

import Foundation
import CoreLocation
import MapKit

// MARK: UserData Struct and Functions
struct UserData: Codable {
    let drives: [[VisitedLocation]]
}

struct VisitedLocation: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let time: Date
    
    func getCLLocation() -> CLLocation {
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude),
                                                             longitude: CLLocationDegrees(longitude)),
                          altitude: CLLocationDistance(altitude),
                          horizontalAccuracy: CLLocationAccuracy(-1),
                          verticalAccuracy: CLLocationAccuracy(-1),
                          timestamp: time)
    }
}

func readDrives() -> [[CLLocation]] {
    var pastDrives: [[CLLocation]] = []
    let decoder = JSONDecoder()
    
    let path = getUserDataPath()
    do {
        let encodedData = try Data(contentsOf: path)
        let data = try decoder.decode(UserData.self, from: encodedData)
        
        for drive in data.drives {
            let mappedDrive = drive.map {$0.getCLLocation()}
            pastDrives.append(mappedDrive)
        }
    } catch CocoaError.fileReadNoSuchFile {
        print("creating file")
        createUserDataFile()
    } catch DecodingError.dataCorrupted(let context) {
        print("json corrupted: \(context.debugDescription)")
        removeUserDataFile()
        createUserDataFile()
    } catch {
        print("reading error: \(error)")
    }
    
    return pastDrives
}

func writeDrives(_ drives: [[CLLocation]]) {
    var encodableDrives: [[VisitedLocation]] = []
    for drive in drives {
        let encodableDrive = drive.map { VisitedLocation(latitude: $0.coordinate.latitude,
                                                         longitude: $0.coordinate.longitude,
                                                         altitude: $0.altitude,
                                                         time: $0.timestamp)}
        encodableDrives.append(encodableDrive)
    }
    
    writeUserData(UserData(drives: encodableDrives))
}

func writeUserData(_ data: UserData) {
    let encoder = JSONEncoder()
    let encodedData: Data
    do {
        encodedData = try encoder.encode(data)
    } catch {
        print("encoding error: \(error)")
        return
    }
    
    let path = getUserDataPath()
    do {
        try encodedData.write(to: path)
    } catch {
        print("writing error: \(error)")
    }
}

func getUserDataPath() -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let path = dir.appendingPathComponent("lt-userdata")
    
    return path
}

func createUserDataFile() {
    let fm = FileManager()
    fm.createFile(atPath: getUserDataPath().path, contents: nil, attributes: nil)
    writeUserData(UserData(drives: []))
}

func removeUserDataFile() {
    let fm = FileManager()
    do {
        try fm.removeItem(at: getUserDataPath())
    } catch {
        print("file remove error: \(error)")
    }
}

// MARK: Visited Overlays
func getPastVisitedOverlays(_ drives: [[CLLocation]]) -> [MKPolyline] {
    var overlays: [MKPolyline] = []
    var coordGroups: [[CLLocationCoordinate2D]] = []
    
    if drives.count == 0 {
        return []
    }
    
    for drive in drives {
        coordGroups.append(drive.map {$0.coordinate})
    }
    
    for arr in coordGroups {
        overlays.append(MKPolyline(coordinates: arr, count: arr.count))
    }
    
    return overlays
}

extension CLLocation {
    func wasVisited(checkedAgainst previousArr: [CLLocation]) -> Bool {
        
    }
}
