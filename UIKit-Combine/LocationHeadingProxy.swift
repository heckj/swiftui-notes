//
//  LocationHeadingProxy.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/13/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import CoreLocation
import Foundation

final class LocationHeadingProxy: NSObject, CLLocationManagerDelegate {
    let mgr: CLLocationManager
    private let headingPublisher: PassthroughSubject<CLHeading, Error>
    var publisher: AnyPublisher<CLHeading, Error>

    override init() {
        mgr = CLLocationManager()
        headingPublisher = PassthroughSubject<CLHeading, Error>()
        publisher = headingPublisher.eraseToAnyPublisher()

        super.init()
        mgr.delegate = self
    }

    func enable() {
        mgr.startUpdatingHeading()
    }

    func disable() {
        mgr.stopUpdatingHeading()
    }

    // MARK: - delegate methods

    /*
     *  locationManager:didUpdateHeading:
     *
     *  Discussion:
     *    Invoked when a new heading is available.
     */
    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingPublisher.send(newHeading)
    }

    /*
     *  locationManager:didFailWithError:
     *  Discussion:
     *    Invoked when an error has occurred. Error types are defined in "CLError.h".
     */
    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        headingPublisher.send(completion: Subscribers.Completion.failure(error))
    }
}
