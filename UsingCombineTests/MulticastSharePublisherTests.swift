//
//  MulticastSharePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 3/1/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class MulticastSharePublisherTests: XCTestCase {
    var sourceValue = 0

    func sourceGenerator() -> Int {
        sourceValue += 1
        return sourceValue
    }

    enum TestFailureCondition: Error {
        case anErrorExample
    }

    // example of a asynchronous function to be called from within a Future and its completion closure
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Int, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1 ... 3)
            print(" * making async call (delay of \(delay) seconds)")
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(0, TestFailureCondition.anErrorExample)
            }
            completionBlock(self.sourceGenerator(), nil)
        }
    }

    func testDeferredFuturePublisher() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)

        // the creating the deferred, future publisher
        let pub = Deferred {
            Future<Int, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
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
        let firstCompletion = XCTestExpectation(description: debugDescription)
        firstCompletion.expectedFulfillmentCount = 2

        let secondCompletion = expectation(description: debugDescription)
        let secondValue = expectation(description: debugDescription)
        secondValue.isInverted = true

        // the creating the deferred, future publisher
        let pub = Deferred {
            Future<Int, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
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

        var sinkValues = [Int]()

        let otherCancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            firstCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            sinkValues.append(value)
        })

        // driving it by attaching it to .sink
        let cancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            firstCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            sinkValues.append(value)
        })

        wait(for: [firstCompletion], timeout: 5.0)

        // drive the publisher again.
        // Note that we won't receive a value this time, just the completion.
        let thirdCancellable = pub.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            secondCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            sinkValues.append(value)
            secondValue.fulfill()
        })

        wait(for: [secondCompletion, secondValue], timeout: 5.0)

        XCTAssertEqual(sinkValues.count, 2)
        XCTAssertEqual(sinkValues[0], sinkValues[1])
        XCTAssertNotNil(cancellable)
        XCTAssertNotNil(otherCancellable)
        XCTAssertNotNil(thirdCancellable)
    }

    func testMulticastDeferredFuturePublisher() {
        // setup
        let firstCompletion = XCTestExpectation(description: debugDescription)
        let firstValues = XCTestExpectation(description: debugDescription)
        firstCompletion.expectedFulfillmentCount = 2
        firstValues.expectedFulfillmentCount = 2

        let secondCompletion = expectation(description: debugDescription)
        let secondValue = expectation(description: debugDescription)
        secondValue.isInverted = true

        let pipelineFork = PassthroughSubject<Int, Error>()

        var cancellables = Set<AnyCancellable>()

        var sinkValues = [Int]()

        // the creating the deferred, future publisher
        let publisher = Deferred {
            Future<Int, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
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
                firstCompletion.fulfill()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
                sinkValues.append(value)
                firstValues.fulfill()
            })
            .store(in: &cancellables)

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            firstCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            sinkValues.append(value)
            firstValues.fulfill()
        })
        .store(in: &cancellables)

        publisher
            .connect()
            .store(in: &cancellables)

        wait(for: [firstCompletion, firstValues], timeout: 5.0)
        XCTAssertEqual(sinkValues.count, 2)
        XCTAssertEqual(sinkValues[0], sinkValues[1])

        // Our latecoming subscriber
        publisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            secondCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            sinkValues.append(value)
            secondValue.fulfill()
        })
        .store(in: &cancellables)

        // We won't need to wait long, as the completion should be immediate
        wait(for: [secondCompletion, secondValue], timeout: 1.0)
        XCTAssertEqual(sinkValues.count, 2)
    }

    func testAltMulticastDeferredFuturePublisher() {
        // setup
        let expectation1 = XCTestExpectation(description: debugDescription)
        let expectation2 = XCTestExpectation(description: debugDescription)

        var cancellables = Set<AnyCancellable>()

        // the creating the deferred, future publisher
        let publisher = Deferred {
            Future<Int, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.multicast {
            // alternate way of using multicast that creates the relevant subject inline
            PassthroughSubject<Int, Error>()
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

    // makeConnectable does something similar, but requires the publisher's error to be <Never>
    // meaning that you have already handlded any failure conditions such that the pipeline will
    // always resolve properly and without issue upon something new connecting...

    func testMakeConnectable() {
        // setup
        let firstCompletion = expectation(description: debugDescription)

        let values = expectation(description: debugDescription)
        values.expectedFulfillmentCount = 4

        let waiting = expectation(description: debugDescription)

        var cancellables = Set<AnyCancellable>()

        let publisher = [1, 2].publisher
            .makeConnectable()

        // driving it by attaching it to .sink
        publisher.sink(receiveCompletion: { completion in
            print(".sink1() received the completion: ", String(describing: completion))
            firstCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink1() received value: ", value)
            values.fulfill()
        })
        .store(in: &cancellables)

        // Setup the order in our wait. The first completion won't have ooccured yet.
        waiting.fulfill()

        let autoPublisher = publisher.autoconnect()

        // driving it by attaching it to .sink
        autoPublisher.sink(receiveCompletion: { completion in
            print(".sink2() received the completion: ", String(describing: completion))
        }, receiveValue: { value in
            print(".sink2() received value: ", value)
            values.fulfill()
        })
        .store(in: &cancellables)

        // We should have fulfilled our mock "setup" before anyone received values
        wait(for: [waiting, values, firstCompletion], timeout: 5.0, enforceOrder: true)
    }

    // As the makeConnectable example above, but now with MultiCast we can include an error
    // Setup a "pipeline" inspector before handing the publisher back to the unsuspecting
    // original subscriber

    func testMulticastDeferredFutureAutoConnectPublisher() {
        // setup
        let doSomeSpyWork = expectation(description: debugDescription)
        let legitCompletion = expectation(description: debugDescription)
        let spyCompletion = expectation(description: debugDescription)
        let spyValueReceived = expectation(description: debugDescription)
        let legitValueReceived = expectation(description: debugDescription)

        var cancellables = Set<AnyCancellable>()

        // the creating the deferred, future publisher
        let publisher = Deferred {
            Future<Int, Error> { promise in
                self.asyncAPICall(sabotage: false) { grantedAccess, err in
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        promise(.success(grantedAccess))
                    }
                }
            }
        }.multicast {
            // alternate way of using multicast that creates the relevant subject inline
            PassthroughSubject<Int, Error>()
        }

        // Attach our 'spy' subscriber. The publisher won't receive a 'send' .... yet
        publisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            spyCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            spyValueReceived.fulfill()
        })
        .store(in: &cancellables) // Note: the spy needs to keep a reference to his own subscriber

        // Our spy has some work to do now before hands back the intercepted publisher
        doSomeSpyWork.fulfill()

        // Now hand off the publisher to the real subscriber
        let spyedPublisher = publisher.autoconnect()
        spyedPublisher.sink(receiveCompletion: { completion in
            print(".sink() received the completion: ", String(describing: completion))
            legitCompletion.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            legitValueReceived.fulfill()
        })
        .store(in: &cancellables)

        wait(for: [doSomeSpyWork, spyValueReceived], timeout: 5.0, enforceOrder: true)
        wait(for: [legitValueReceived, legitCompletion, spyCompletion], timeout: 5.0)
    }
}
