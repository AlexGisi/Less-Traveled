//
//  UserData.swift
//  Less Traveled
//
//  Created by Alex Gisi on 12/22/20.
//

import Foundation
import CoreLocation

// MARK: UserData Struct and Functions
struct UserData: Codable {
    let visited: [VisitedLocation]
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

func readVisitedLocations() -> [CLLocation] {
    var visited: [CLLocation] = []
    let decoder = JSONDecoder()
    
    let path = getUserDataPath()
    do {
        let encodedData = try Data(contentsOf: path)
        let data = try decoder.decode(UserData.self, from: encodedData)
        
        visited = data.visited.map {$0.getCLLocation()}
    } catch CocoaError.fileReadNoSuchFile {
        print("creating file")
        createUserDataFile()
    } catch {
        print("reading error: \(error)")
    }
    
    return visited
}

func writeVisitedLocations(past pastVisited: [CLLocation], just justVisited: [CLLocation]) {
    let visited: [CLLocation] = pastVisited + justVisited
    let encodableVisited: [VisitedLocation] = visited.map {VisitedLocation(latitude: $0.coordinate.latitude,
                                                                           longitude: $0.coordinate.longitude,
                                                                           altitude: $0.altitude,
                                                                           time: $0.timestamp)}
    
    let data = UserData(visited: encodableVisited)
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
        print("wrote to \(getUserDataPath().path)")
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
}
