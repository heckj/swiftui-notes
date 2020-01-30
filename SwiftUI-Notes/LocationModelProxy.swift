//
//  LocationModelProxy.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/18/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Foundation
import Combine
import CoreLocation

final class LocationProxy: NSObject, CLLocationManagerDelegate, ObservableObject {
    let mgr: CLLocationManager
    private let headingSubject: PassthroughSubject<CLHeading, Never>
    private let locationSubject: PassthroughSubject<CLLocation, Never>
    var headingPublisher: AnyPublisher<CLHeading, Never>
    var locationPublisher: AnyPublisher<CLLocation, Never>

    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var active = false

    func requestAuthorization() {
        mgr.requestWhenInUseAuthorization()
    }
    
    func authorizationStatusString() -> String {
        switch self.authorizationStatus {
        case .authorizedWhenInUse:
            return "Allowed When In Use"
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        @unknown default:
            return "unknown"
        }
    }

    override init() {
        mgr = CLLocationManager()
        authorizationStatus = CLLocationManager.authorizationStatus()
        headingSubject = PassthroughSubject<CLHeading, Never>()
        locationSubject = PassthroughSubject<CLLocation, Never>()
        headingPublisher = headingSubject.eraseToAnyPublisher()
        locationPublisher = locationSubject.eraseToAnyPublisher()

        super.init()
        mgr.delegate = self
        if (authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse) {
            enable()
        }
    }

    func enable() {
        mgr.startUpdatingHeading()
        mgr.startUpdatingLocation()
        self.active = true
    }

    func disable() {
        mgr.stopUpdatingHeading()
        mgr.stopUpdatingLocation()
        self.active = false
    }
    // MARK - delegate methods

    // delegate method from CLLocationManagerDelegate - updates on authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if (status == .authorizedAlways || status == .authorizedWhenInUse) {
            self.enable()
        } else {
            self.disable()
        }
    }

    /*
     *  locationManager:didUpdateHeading:
     *
     *  Discussion:
     *    Invoked when a new heading is available.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // NOTE(heckj): simulator will *NOT* trigger this value, but it will send location updates
        // print(newHeading)
        headingSubject.send(newHeading)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // print(locations)
        for loc in locations {
            locationSubject.send(loc)
        }
    }
}
