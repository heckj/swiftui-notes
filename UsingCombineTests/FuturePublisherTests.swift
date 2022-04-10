//
//  FuturePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class FuturePublisherTests: XCTestCase {
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

    func testFuturePublisher() {
        // setup
        var outputValue = false
        let expectation = XCTestExpectation(description: debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            self.asyncAPICall(sabotage: false) { grantedAccess, err in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }

        // driving it by attaching it to .sink
        let cancellable = sut.sink(receiveCompletion: { err in
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

    func testFuturePublisherShowingFailure() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            self.asyncAPICall(sabotage: true) { grantedAccess, err in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }

        // driving it by attaching it to .sink
        let cancellable = sut.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            XCTAssertNotNil(err)
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            XCTFail("no value should be returned")
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testFuturePublisherShowingFailureWithRetry() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)
        var asyncAPICallCount = 0
        var futureClosureHandlerCount = 0

        // example of a asynchronous function to be called from within a Future and its completion closure
        func instrumentedAsyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
            DispatchQueue.global(qos: .background).async {
                let delay = Int.random(in: 1 ... 3)
                print(" * making async call (delay of \(delay) seconds)")
                asyncAPICallCount += 1
                sleep(UInt32(delay))
                if sabotage {
                    completionBlock(false, TestFailureCondition.anErrorExample)
                }
                completionBlock(true, nil)
            }
        }

        let deferredFuturePublisher = Deferred {
            Future<Bool, Error> { promise in
                futureClosureHandlerCount += 1
                // setting "sabotage: true" in the asyncAPICall tells the test code to return a
                // failure result, which will illustrate "retry" better.
                instrumentedAsyncAPICall(sabotage: true) { grantedAccess, err in
                    print("invoking async completion handler to return a resolved promise")
                    // NOTE(heckj): the closure resolving the API call into a Promise result
                    // is called more than 3 times - 5 in this example, although I don't know
                    // why that is. The underlying API call, and the closure within the future
                    // are each called 3 times - validated below in the assertions.
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.eraseToAnyPublisher()
            .retry(2)

        XCTAssertEqual(asyncAPICallCount, 0)
        XCTAssertEqual(futureClosureHandlerCount, 0)

        let cancellable = deferredFuturePublisher.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))

            // the end result should have 3 calls (the original, plus 2 retries,
            // made to the api endpoint defined in the Future
            XCTAssertEqual(asyncAPICallCount, 3)
            XCTAssertEqual(futureClosureHandlerCount, 3)
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            XCTFail("no value should be returned")
        })

        wait(for: [expectation], timeout: 10.0)
        XCTAssertNotNil(cancellable)
    }

    func testResolvedFutureSuccess() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)

        let resolvedSuccessAsPublisher = Future<Bool, Error> { promise in
            promise(.success(Bool()))
        }.eraseToAnyPublisher()

        let cancellable = resolvedSuccessAsPublisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            XCTAssertNotNil(completion)
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }

    func testResolvedFutureFailure() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)

        enum ExampleFailure: Error {
            case oneCase
        }

        let resolvedFailureAsPublisher = Future<Bool, Error> { promise in
            promise(.failure(ExampleFailure.oneCase))
        }.eraseToAnyPublisher()

        let cancellable = resolvedFailureAsPublisher.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            XCTAssertNotNil(err)
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            XCTFail("no value should be returned")
        })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }

    func testDeferredFuturePublisherWithRetry() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            print("invoking Future handler for resolving the provided promise")
            self.asyncAPICall(sabotage: true) { grantedAccess, err in
                print("invoking async completion handler to return a resolved promise")
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }
        .print("before_retry:")
        .retry(2)
        .print("after_retry:")

        // driving it by attaching it to .sink
        let cancellable = sut.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            XCTAssertNotNil(err)
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            XCTFail("no value should be returned")
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testFutureWithinAFlatMap() {
        let simplePublisher = PassthroughSubject<String, Never>()
        var outputValue: String?

        let cancellable = simplePublisher
            .print(debugDescription)
            .flatMap { name in
                Future<String, Error> { promise in
                    promise(.success(name))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    "\(result) foo"
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
        XCTAssertNotNil(cancellable)
    }
}
