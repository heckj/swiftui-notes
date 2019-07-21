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

    @IBAction func startButtonPressed(_ sender: UIButton) {

    }

    var coordinatedPipeline: AnyPublisher<Bool, Error>?

    // MARK: - helper pieces that would normally be in other files

    // this emulates an async API call with a completion callback
    // it does nothing other than wait and ultimately return with a boolean value
    func randomAsyncAPI(completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            sleep(.random(in: 2...5))
            completionBlock(true, nil)
        }
    }

    func createFuturePublisher() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.randomAsyncAPI() { (result, err) in
                if let err = err {
                    promise(.failure(err))
                }
                promise(.success(result))
            }
        }.eraseToAnyPublisher()
    }

    func markStepDone(button: UIButton) {
        button.backgroundColor = .systemGreen
        button.isHighlighted = true
    }

    // MARK: - view setup

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        coordinatedPipeline = createFuturePublisher()
            .receive(on: RunLoop.main) // convenience to make it easy to tweak the UI to display progress
            .map { _ -> Bool in
                // intentially side effecting here to show progress of pipeline
                self.markStepDone(button: self.step1_button)
                return true
            }
        .flatMap { _ in
            return self.createFuturePublisher()
            //            let step2_1 = self.createFuturePublisher()
//                .receive(on: RunLoop.main) // convenience to make it easy to tweak the UI to display progress
//                .map {
//                    // intentially side effecting here to show progress of pipeline
//                    self.markStepDone(button: self.step2_1_button)
//                    return $0
//                }
//
//            let step2_2 = self.createFuturePublisher()
//                .receive(on: RunLoop.main) // convenience to make it easy to tweak the UI to display progress
//                .map {
//                    // intentially side effecting here to show progress of pipeline
//                    self.markStepDone(button: self.step2_2_button)
//                    return $0
//                }
//
//            let step2_3 = self.createFuturePublisher()
//                .receive(on: RunLoop.main) // convenience to make it easy to tweak the UI to display progress
//                .map {
//                    // intentially side effecting here to show progress of pipeline
//                    self.markStepDone(button: self.step2_3_button)
//                    return $0
//                }
//
//            return Publishers.Zip3(step2_1, step2_2, step2_3)
//                .map { _ -> Bool in
//                    return true
//                }.eraseToAnyPublisher()

            }
        .eraseToAnyPublisher() as AnyPublisher<Bool, Error>


//        // driving it by attaching it to .sink
//        let cancellable = futurePublisher.sink(receiveCompletion: { err in
//            print(".sink() received the completion: ", String(describing: err))
//            expectation.fulfill()
//        }, receiveValue: { value in
//            print(".sink() received value: ", value)
//            outputValue = value
//        })

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
