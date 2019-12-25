//
//  AsyncCoordinatorViewController.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/21/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import UIKit
import Combine

class AsyncCoordinatorViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var step1_button: UIButton!
    @IBOutlet weak var step2_1_button: UIButton!
    @IBOutlet weak var step2_2_button: UIButton!
    @IBOutlet weak var step2_3_button: UIButton!
    @IBOutlet weak var step3_button: UIButton!
    @IBOutlet weak var step4_button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var cancellable: AnyCancellable?
    var coordinatedPipeline: AnyPublisher<Bool, Error>?

    @IBAction func doit(_ sender: Any) {
        runItAll()
    }

    func runItAll() {
        if self.cancellable != nil {
            print("Cancelling existing run")
            cancellable?.cancel()
            self.activityIndicator.stopAnimating()
        }
        print("resetting all the steps")
        self.resetAllSteps()
        // driving it by attaching it to .sink
        self.activityIndicator.startAnimating()
        print("attaching a new sink to start things going")
        self.cancellable = coordinatedPipeline?
            .print()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion: ", String(describing: completion))
                self.activityIndicator.stopAnimating()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
            })
    }
    // MARK: - helper pieces that would normally be in other files

    // this emulates an async API call with a completion callback
    // it does nothing other than wait and ultimately return with a boolean value
    func randomAsyncAPI(completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            sleep(.random(in: 1...4))
            completionBlock(true, nil)
        }
    }

    /// Creates and returns pipeline that uses a Future to wrap randomAsyncAPI, then updates a UIButton to represent
    /// the completion of the async work before returning a boolean True
    /// - Parameter button: button to be updated
    func createFuturePublisher(button: UIButton) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.randomAsyncAPI() { (result, err) in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(result))
                }
            }
        }
        .receive(on: RunLoop.main)
            // so that we can update UI elements to show the "completion"
            // of this step
        .map { inValue -> Bool in
            // intentially side effecting here to show progress of pipeline
            self.markStepDone(button: button)
            return true
        }
        .eraseToAnyPublisher()
    }

    /// highlights a button and changes the background color to green
    /// - Parameter button: reference to button being updated
    func markStepDone(button: UIButton) {
        button.backgroundColor = .systemGreen
        button.isHighlighted = true
    }

    func resetAllSteps() {
        for button in [self.step1_button, self.step2_1_button, self.step2_2_button, self.step2_3_button, self.step3_button, self.step4_button] {
            button?.backgroundColor = .lightGray
            button?.isHighlighted = false
        }
        self.activityIndicator.stopAnimating()
    }

    // MARK: - view setup

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.stopAnimating()

        // Do any additional setup after loading the view.

        coordinatedPipeline = createFuturePublisher(button: self.step1_button)
            .flatMap { flatMapInValue -> AnyPublisher<Bool, Error> in
            let step2_1 = self.createFuturePublisher(button: self.step2_1_button)
            let step2_2 = self.createFuturePublisher(button: self.step2_2_button)
            let step2_3 = self.createFuturePublisher(button: self.step2_3_button)
            return Publishers.Zip3(step2_1, step2_2, step2_3)
                .map { _ -> Bool in
                    return true
                }
                .eraseToAnyPublisher()
            }
        .flatMap { _ in
            return self.createFuturePublisher(button: self.step3_button)
        }
        .flatMap { _ in
            return self.createFuturePublisher(button: self.step4_button)
        }
        .eraseToAnyPublisher()
    }
}
