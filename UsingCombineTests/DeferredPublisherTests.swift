//
//  DeferredPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class DeferredPublisherTests: XCTestCase {
    enum TestFailureCondition: Error {
        case anErrorExample
    }

    // example of a asynchronous function to be called from within a Future and its completion closure
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1 ... 3)
            print(" * making async call (delay of \(delay) seconds)")
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(false, TestFailureCondition.anErrorExample)
            }
            completionBlock(true, nil)
        }
    }

    func testDeferredFuturePublisher() {
        // setup
        var outputValue = false
        let expectation = XCTestExpectation(description: debugDescription)

        let deferredPublisher = Deferred {
            Future<Bool, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
                    if let err = err {
                        return promise(.failure(err))
                    }
                    return promise(.success(grantedAccess))
                }
            }
        }.eraseToAnyPublisher()

        // the creating the future publisher

        // driving it by attaching it to .sink
        let cancellable = deferredPublisher.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            outputValue = value
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(outputValue)
        XCTAssertNotNil(cancellable)
    }

    func testDeferredPublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let deferredPublisher = Deferred {
            Just("hello")
        }.eraseToAnyPublisher()

        // The core of "Deferred" is that the closure that generates the published is not invoked
        // until a subscriber is attached, then it creates the publisher "just in time".
        // I'm afraid I haven't figured out any sane way to illustrate that with a unit test...

        let cancellable = deferredPublisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { valueReceived in
                XCTAssertEqual(valueReceived, "hello")
                print(".sink() data received \(valueReceived)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }
}
