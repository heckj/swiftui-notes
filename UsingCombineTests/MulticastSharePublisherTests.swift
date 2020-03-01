//
//  MulticastSharePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 3/1/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class MulticastSharePublisherTests: XCTestCase {

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

    func testDeferredFuturePublisher() {
        // setup
        let expectation = XCTestExpectation(description: self.debugDescription)

        // the creating the deferred, future publisher
        let pub = Deferred {
            Future<Bool, Error> { promise in
                self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }

        // driving it by attaching it to .sink
        let cancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)

        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testSharedDeferredFuturePublisher() {
        // setup
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        let expectation2 = XCTestExpectation(description: self.debugDescription)

        // the creating the deferred, future publisher
        let pub = Deferred {
            Future<Bool, Error> { promise in
                self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.share()
        // share() provides a sort of encapsulation for demand - it creates a reference
        // such that any number of subscribers can ask for a resource, and it will translate
        // that into a single request - only one subscription being made 'upstream'

        let otherCancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            expectation1.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })

        // driving it by attaching it to .sink
        let cancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            expectation2.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)

        })

        wait(for: [expectation1, expectation2], timeout: 5.0)
        XCTAssertNotNil(cancellable)
        XCTAssertNotNil(otherCancellable)
    }

    func testMulticastDeferredFuturePublisher() {
        // setup
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        let expectation2 = XCTestExpectation(description: self.debugDescription)

        let pipelineFork = PassthroughSubject<Bool, Error>()

        var cancellables = Set<AnyCancellable>()

        // the creating the deferred, future publisher
        let publisher = Deferred {
            Future<Bool, Error> { promise in
                self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.multicast(subject: pipelineFork)

        publisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion: ", String(describing: completion))
                expectation1.fulfill()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
            })
            .store(in: &cancellables)

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            expectation2.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })
        .store(in: &cancellables)

        publisher
            .connect()
            .store(in: &cancellables)

        wait(for: [expectation1, expectation2], timeout: 5.0)
    }

    func testAltMulticastDeferredFuturePublisher() {
        // setup
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        let expectation2 = XCTestExpectation(description: self.debugDescription)

        var cancellables = Set<AnyCancellable>()

        // the creating the deferred, future publisher
        let publisher = Deferred {
            Future<Bool, Error> { promise in
                self.asyncAPICall(sabotage: false) { (grantedAccess, err) in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.multicast {
            // alternate way of using multicast that creates the relevant subject inline
            PassthroughSubject<Bool, Error>()
        }

        publisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion: ", String(describing: completion))
                expectation1.fulfill()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
            })
            .store(in: &cancellables)

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            expectation2.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })
        .store(in: &cancellables)

        publisher
            .connect()
            .store(in: &cancellables)

        wait(for: [expectation1, expectation2], timeout: 5.0)
    }

    // makeConnectable does something similiar, but requires the publisher's error to be <Never>
    // meaning that you have already handlded any failure conditions such that the pipeline will
    // always resolve properly and without issue upon something new connecting...

    func testMakeConnectable() {
        // setup
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        let expectation2 = XCTestExpectation(description: self.debugDescription)
        var cancellables = Set<AnyCancellable>()

        let publisher = Just("woot")
            .print("a")
            .multicast(subject: PassthroughSubject<String, Never>())
            .print("b")
            .makeConnectable()

        publisher
            .connect()
            .store(in: &cancellables)

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink1() received the completion: ", String(describing: completion))
            expectation1.fulfill()
        }, receiveValue: { value in
            print(".sink1() received value: ", value)
        })
        .store(in: &cancellables)

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink2() received the completion: ", String(describing: completion))
            expectation2.fulfill()
        }, receiveValue: { value in
            print(".sink2() received value: ", value)
        })
        .store(in: &cancellables)

        wait(for: [expectation1, expectation2], timeout: 5.0)
    }

}
