//
//  DebounceAndRemoveDuplicatesPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class DebounceAndRemoveDuplicatesPublisherTests: XCTestCase {

    func testRemoveDuplicates() {
        let simplePublisher = PassthroughSubject<String, Error>()

        var mostRecentlyReceivedValue: String? = nil
        var receivedValueCount = 0

        let cancellable = simplePublisher
            .removeDuplicates()
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                    break
                case .finished:
                    break
                }
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
                mostRecentlyReceivedValue = stringValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)

        // first value is processed through the pipeline
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 1)
        // resend of that same value isn't received by .sink
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 1)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send("twofish")
        XCTAssertEqual(mostRecentlyReceivedValue, "twofish")
        XCTAssertEqual(receivedValueCount, 2)
        // resend of that same value isn't received by .sink
        simplePublisher.send("twofish")
        XCTAssertEqual(mostRecentlyReceivedValue, "twofish")
        XCTAssertEqual(receivedValueCount, 2)

        // An earlier value will get passed through as long as
        // it's not the one that just recently was seen
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }


    func testRemoveDuplicatesWithoutEquatable() {
        struct AnExampleStruct {
            let id: Int
        }

        let simplePublisher = PassthroughSubject<AnExampleStruct, Error>()

        var mostRecentlyReceivedValue: AnExampleStruct? = nil
        var receivedValueCount = 0

        let cancellable = simplePublisher
            .removeDuplicates(by: { first, second -> Bool in
                first.id == second.id
            })
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                    break
                case .finished:
                    break
                }
            }, receiveValue: { someValue in
                print(".sink() received \(someValue)")
                mostRecentlyReceivedValue = someValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)

        // first value is processed through the pipeline
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)

        // An earlier value will get passed through as long as
        // it's not the one that just recently was seen
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testTryRemoveDuplicates() {
        struct AnExampleStruct {
            let id: Int
        }

        enum TestFailure: Error {
            case boom
        }

        let simplePublisher = PassthroughSubject<AnExampleStruct, Error>()

        var mostRecentlyReceivedValue: AnExampleStruct? = nil
        var receivedValueCount = 0
        var receivedError = false

        let cancellable = simplePublisher
            .tryRemoveDuplicates(by: { first, second -> Bool in
                if (first.id == 5 || second.id == 5) {
                    // a contrived example showing the exception
                    throw TestFailure.boom
                }
                return first.id == second.id
            })
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    receivedError = true
                    break
                case .finished:
                    XCTFail("no completion should be received")
                    break
                }
            }, receiveValue: { someValue in
                print(".sink() received \(someValue)")
                mostRecentlyReceivedValue = someValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)
        XCTAssertFalse(receivedError)

        // first value is processed through the pipeline
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        XCTAssertFalse(receivedError)

        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        XCTAssertFalse(receivedError)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertFalse(receivedError)

        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertFalse(receivedError)

        // We send a value that causes an exception to be thrown
        simplePublisher.send(AnExampleStruct(id: 5))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertTrue(receivedError)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testDebounce() {

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        var receivedCount = 0

        let cancellable = foo.$intValue
            .debounce(for: 0.5, scheduler: q)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedCount += 1
            }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 1
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 2
        })
        q.asyncAfter(deadline: .now() + 0.3, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 3
        })

        q.asyncAfter(deadline: .now() + 1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 10
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedCount, 2)
        XCTAssertEqual(foo.intValue, 10)
        XCTAssertNotNil(cancellable)
    }

    func testThrottleLatestFalse() {

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propogated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(self.debugDescription)
            .sink { someValue in
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 1
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 2
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 3
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 4
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 5
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
            // this value is collapsed by the throttle and not passed through to sink
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 3)

        // NOTE(heckj): this changed in Xcode 11.2 (iOS 13.2):
        // of the values sent at 1.1 and 1.2 seconds in, the second value is returned down the pipeline
        // and prior to that it returned the first value - so the value of "false" for recent from throttle
        // doesn't appear to be respected. - reported as FB7424221
        //
        // This updated again in Xcode 11.3 (iOS 13.3), and now throttle(true) and throttle(false) exhibit
        // different behavior again.
        //
        //XCTAssertEqual(receivedList, [-1, 5, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.3
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }
    
    func testThrottleLatestTrue() {

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propogated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 1
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 2
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 3
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 4
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 5
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 3)
        // The values sent at 0.1 and 0.2 seconds in get collapsed, being within the 0.5 sec window
        // and requesting just the "latest" value - so the total number of events received by the sink
        // is fewer than the number sent.
        // XCTAssertEqual(receivedList, [2, 5, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.3
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }

    func SKIP_testSubjectThrottleLatestAtWindowFalse() {
        // I'm setting this test to generally skip, since it's not going to consistently run
        // in the same fashion under CI as it does on my laptop. Since I'm pushing out values
        // right at the edge of the timing window in this test case, the results are hyper-sensitive
        // to slightly slower systems (such as VMs as in the CI system)

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(self.debugDescription)
            .sink { someValue in
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(1);
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(2);
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(3);
        // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4);
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(5);
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6);
            // this value is collapsed by the throttle and not passed through to sink
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 3)

        // NOTE(heckj): this changed in Xcode 11.2 (iOS 13.2):
        // of the values sent at 1.1 and 1.2 seconds in, the second value is returned down the pipeline
        // and prior to that it returned the first value - so the value of "false" for recent from throttle
        // doesn't appear to be respected. - reported as FB7424221
        //
        // This updated again in Xcode 11.3 (iOS 13.3), and now throttle(true) and throttle(false) exhibit
        // different behavior again.
        //
        //XCTAssertEqual(receivedList, [3, 5]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 4, 5]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func SKIP_testSubjectThrottleLatestAtWindowTrue() {
        // I'm setting this test to generally skip, since it's not going to consistently run
        // in the same fashion under CI as it does on my laptop. Since I'm pushing out values
        // right at the edge of the timing window in this test case, the results are hyper-sensitive
        // to slightly slower systems (such as VMs as in the CI system)

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 3)
        // The values sent at 0.1 and 0.2 seconds in get collapsed, being within the 0.5 sec window
        // and requesting just the "latest" value - so the total number of events received by the sink
        // is fewer than the number sent.
        // XCTAssertEqual(receivedList, [3, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 4, 6]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSpreadoutSubjectThrottleLatestFalse() {

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(self.debugDescription)
            .sink { someValue in
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(1);
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(2);
        })
        q.asyncAfter(deadline: .now() + 0.8, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(3);
        })
        q.asyncAfter(deadline: .now() + 0.9, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4);
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 1.5, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(5);
        })
        q.asyncAfter(deadline: .now() + 1.6, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6);
            // this value is collapsed by the throttle and not passed through to sink
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)
        //XCTAssertEqual(receivedList, [1, 3, 5]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 2, 3, 5]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSpreadoutSubjectThrottleLatestTrue() {

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
        })
        q.asyncAfter(deadline: .now() + 0.8, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.9, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        })
        q.asyncAfter(deadline: .now() + 1.5, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.6, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)
        // XCTAssertEqual(receivedList, [2, 4, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 2, 4, 6]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSubjectDebounce() {

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .debounce(for: 0.5, scheduler: q)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        // this is the same timing pattern as the throttle tests above, for comparison
        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedList, [6]) // iOS 13.2.2 and 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSubjectDebounceWithBreak() {

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .debounce(for: 0.5, scheduler: q)
            .print(self.debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
        })
        q.asyncAfter(deadline: .now() + 1.1, execute: {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propogated
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4)
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedList, [2, 4]) // iOS 13.2.2 and 13.3
        XCTAssertNotNil(cancellable)
    }
}
