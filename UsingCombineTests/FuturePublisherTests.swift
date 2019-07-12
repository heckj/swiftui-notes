//
//  FuturePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine


class FuturePublisherTests: XCTestCase {

    enum testFailureCondition: Error {
        case anErrorExample
    }

    // example of blocking function
    func aBlockingFunction() -> String {
        sleep(.random(in: 1...3))
        return "Hello world!"
    }
    // example of a functional calling it with a completion closure
    func asyncMethod(completion block: @escaping ((String) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let result = self.aBlockingFunction()
            block(result)
        }
    }

    func testFuturePublisher() {
        // setup
        var outputValue: String? = nil
        let expectation = XCTestExpectation(description: self.debugDescription)

        // the creating the future publisher
        let sut = Future<String, Error> { promise in
//            yourAPICallThatTakesAClosure(someParam) { resultData in
//                // on successful resultData
//                promise(.success("a success response"))
//            }
            print("Setting up the future with an incoming promise: ", promise) // <-- initialized promise that we resolve
            promise(.success("a success response"))
            // or
            promise(.failure(testFailureCondition.anErrorExample))
        }

        // driving it by attaching it to .sink
        let _ = sut.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            outputValue = value
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(outputValue, "a success response")
    }

    func testFutureWithinAFlatMap() {
        let simplePublisher = PassthroughSubject<String, Never>()
        var outputValue: String? = nil

        let _ = simplePublisher
            .print(self.debugDescription)
            .flatMap { name in
                return Future<String, Error> { promise in
                    promise(.success(name))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    return "\(result) foo"
                }
            }
            .sink(receiveCompletion: { err in
                print(".sink() received the completion", String(describing: err))
            }, receiveValue: { value in
                print(".sink() received \(String(describing: value))")
                outputValue = value
            })

        XCTAssertNil(outputValue)
        simplePublisher.send("one")
        XCTAssertEqual(outputValue, "one foo")
    }


}
