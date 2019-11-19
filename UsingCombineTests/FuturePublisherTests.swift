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

    enum TestFailureCondition: Error {
        case anErrorExample
    }

    // example of a asynchronous function to be called from within a Future and its completion closure
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1...3)
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
        var outputValue: Bool = false
        let expectation = XCTestExpectation(description: self.debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                if let err = err {
                    promise(.failure(err))
                }
                promise(.success(grantedAccess))
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
        let expectation = XCTestExpectation(description: self.debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            self.asyncAPICall(sabotage: true) { (grantedAccess, err) in
                if let err = err {
                    promise(.failure(err))
                }
                promise(.success(grantedAccess))
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
        let expectation = XCTestExpectation(description: self.debugDescription)

        // the creating the future publisher
        let sut = Future<Bool, Error> { promise in
            print("invoking Future handler for resolving the provided promise")
            self.asyncAPICall(sabotage: true) { (grantedAccess, err) in
                print("invoking async completion handler to return a resolved promise")
                if let err = err {
                    promise(.failure(err))
                }
                promise(.success(grantedAccess))
            }
        }
        .print("before_retry:")
        .retry(2)
        .print("after_retry:")

//        output from this test:
//        invoking Future handler for resolving the provided promise
//        before_retry:: receive subscription: (Future)
//        after_retry:: receive subscription: (Retry)
//        after_retry:: request unlimited
//        before_retry:: request unlimited
//         * making async call (delay of 1 seconds)
//        invoking async completion handler to return a resolved promise
//        before_retry:: receive error: (anErrorExample)
//        before_retry:: receive subscription: (Future)
//        before_retry:: request unlimited
//        before_retry:: receive error: (anErrorExample)
//        before_retry:: receive subscription: (Future)
//        before_retry:: request unlimited
//        before_retry:: receive error: (anErrorExample)
//        after_retry:: receive error: (anErrorExample)
//        .sink() received the completion:  failure(UsingCombineTests.FuturePublisherTests.TestFailureCondition.anErrorExample)

        // NOTE(heckj): from this output, it appears that Future maintain's its internal state of any promise resolutions, and
        // subsequent subscriiption/demand invocations to it as a publisher will not retrigger the provided closures. This
        // implies that it's rather incompatible with the retry() operator.
        //
        // This has been reported to Apple as Feedback : FB7455914

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
        var outputValue: String? = nil

        let cancellable = simplePublisher
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
        XCTAssertNotNil(cancellable)
    }


}
