//
//  LocationModelProxy.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/18/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import CoreLocation
import Foundation

final class LocationProxy: NSObject, CLLocationManagerDelegate, ObservableObject {
    let mgr: CLLocationManager
    private let headingSubject: PassthroughSubject<CLHeading, Never>
    private let locationSubject: PassthroughSubject<CLLocation, Never>
    var headingPublisher: AnyPublisher<CLHeading, Never>
    var locationPublisher: AnyPublisher<CLLocation, Never>

    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var active = false

    func requestAuthorization() {
        mgr.requestWhenInUseAuthorization()
    }

    func authorizationStatusString() -> String {
        switch authorizationStatus {
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
        case .none:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    override init() {
        mgr = CLLocationManager()
        headingSubject = PassthroughSubject<CLHeading, Never>()
        locationSubject = PassthroughSubject<CLLocation, Never>()
        headingPublisher = headingSubject.eraseToAnyPublisher()
        locationPublisher = locationSubject.eraseToAnyPublisher()

        super.init()
        mgr.delegate = self
        if #available(iOS 14, *) {
            // Use iOS 14 APIs, which guarantees that an initial state will be
            // called onto the delegate asserting the current location management
            // status, so the overall flow of data be activated from there.
        } else {
            // if < iOS 14, the CLLocationManager isn't guaranteed to give us an initial
            // callback if everything is kosher, so explicitly check it.
            authorizationStatus = CLLocationManager.authorizationStatus()
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                enableEventForwarding()
            }
        }
    }

    func enableEventForwarding() {
        if CLLocationManager.headingAvailable() {
            mgr.startUpdatingHeading()
        }
        mgr.startUpdatingLocation()
        active = true
    }

    func disableEventForwarding() {
        mgr.stopUpdatingHeading()
        mgr.stopUpdatingLocation()
        active = false
    }

    // MARK: - delegate methods

    // delegate method from CLLocationManagerDelegate - updates on authorization status changes
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            enableEventForwarding()
        } else {
            disableEventForwarding()
        }
    }

    /*
     *  locationManager:didUpdateHeading:
     *
     *  Discussion:
     *    Invoked when a new heading is available.
     */
    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // NOTE(heckj): simulator will *NOT* trigger this value, but it will send location updates
        // print(newHeading)
        headingSubject.send(newHeading)
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // print(locations)
        for loc in locations {
            locationSubject.send(loc)
        }
    }
}
