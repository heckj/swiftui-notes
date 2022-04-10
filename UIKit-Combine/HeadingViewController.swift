//
//  HeadingViewController.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/15/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import CoreLocation
import UIKit

class HeadingViewController: UIViewController {
    var headingSubscriber: AnyCancellable?

    let coreLocationProxy = LocationHeadingProxy()
    var headingBackgroundQueue: DispatchQueue = .init(label: "headingBackgroundQueue")

    // MARK: - lifecycle methods

    @IBOutlet var permissionButton: UIButton!
    @IBOutlet var activateTrackingSwitch: UISwitch!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var locationPermissionLabel: UILabel!

    @IBAction func requestPermission(_: UIButton) {
        print("requesting corelocation permission")
        _ = Future<Int, Never> { promise in
            self.coreLocationProxy.mgr.requestWhenInUseAuthorization()
            return promise(.success(1))
        }
        .delay(for: 2.0, scheduler: headingBackgroundQueue)
        .receive(on: RunLoop.main)
        .sink { _ in
            print("updating corelocation permission label")
            self.updatePermissionStatus()
        }
    }

    @IBAction func trackingToggled(_ sender: UISwitch) {
        switch sender.isOn {
        case true:
            coreLocationProxy.enable()
            print("Enabling heading tracking")
        case false:
            coreLocationProxy.disable()
            print("Disabling heading tracking")
        }
    }

    func updatePermissionStatus() {
        // When originally written (for iOS 13), this method was available
        // for requesting current status at any time. With iOS 14, that's no
        // longer the case and it shows as deprecated, with the expected path
        // to get this information being from a CoreLocationManager Delegate
        // callback.
        let x = CLLocationManager.authorizationStatus()
        switch x {
        case .authorizedWhenInUse:
            locationPermissionLabel.text = "Allowed when in use"
        case .notDetermined:
            locationPermissionLabel.text = "notDetermined"
        case .restricted:
            locationPermissionLabel.text = "restricted"
        case .denied:
            locationPermissionLabel.text = "denied"
        case .authorizedAlways:
            locationPermissionLabel.text = "authorizedAlways"
        @unknown default:
            locationPermissionLabel.text = "unknown default"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // request authorization for the corelocation data
        updatePermissionStatus()

        let corelocationsub = coreLocationProxy
            .publisher
            .print("headingSubscriber")
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { someValue in
                      self.headingLabel.text = String(someValue.trueHeading)
                  })

        headingSubscriber = AnyCancellable(corelocationsub)
    }
}
