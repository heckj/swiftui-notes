//
//  DebounceAndRemoveDuplicatesPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

extension TimeInterval {
    // from https://stackoverflow.com/questions/28872450/conversion-from-nstimeinterval-to-hour-minutes-seconds-milliseconds-in-swift
    // because NSDateComponentFormatter doesn't support sub-second displays :-(

    func toReadableString() -> String {
        // Nanoseconds
        let ns = Int(truncatingRemainder(dividingBy: 1) * 1_000_000_000) % 1000
        // Microseconds
        let us = Int(truncatingRemainder(dividingBy: 1) * 1_000_000) % 1000
        // Milliseconds
        let ms = Int(truncatingRemainder(dividingBy: 1) * 1000)
        // Seconds
        let s = Int(self) % 60
        // Minutes
        let mn = (Int(self) / 60) % 60
        // Hours
        let hr = (Int(self) / 3600)

        var readableStr = ""
        if hr != 0 {
            readableStr += String(format: "%0.2dhr ", hr)
        }
        if mn != 0 {
            readableStr += String(format: "%0.2dmn ", mn)
        }
        if s != 0 {
            readableStr += String(format: "%0.2ds ", s)
        }
        if ms != 0 {
            readableStr += String(format: "%0.3dms ", ms)
        }
        if us != 0 {
            readableStr += String(format: "%0.3dus ", us)
        }
        if ns != 0 {
            readableStr += String(format: "%0.3dns", ns)
        }

        return readableStr
    }
}

class DebounceAndRemoveDuplicatesPublisherTests: XCTestCase {
    func testRemoveDuplicates() {
        let simplePublisher = PassthroughSubject<String, Error>()

        var mostRecentlyReceivedValue: String?
        var receivedValueCount = 0

        let cancellable = simplePublisher
            .removeDuplicates()
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
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

        var mostRecentlyReceivedValue: AnExampleStruct?
        var receivedValueCount = 0

        let cancellable = simplePublisher
            .removeDuplicates(by: { first, second -> Bool in
                first.id == second.id
            })
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
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

        var mostRecentlyReceivedValue: AnExampleStruct?
        var receivedValueCount = 0
        var receivedError = false

        let cancellable = simplePublisher
            .tryRemoveDuplicates(by: { first, second -> Bool in
                if first.id == 5 || second.id == 5 {
                    // a contrived example showing the exception
                    throw TestFailure.boom
                }
                return first.id == second.id
            })
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    receivedError = true
                case .finished:
                    XCTFail("no completion should be received")
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
        let msTime = DateFormatter()
        msTime.dateFormat = "[HH:mm:ss.SSSS] "

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        var receivedCount = 0

        let cancellable = foo.$intValue
            .debounce(for: 0.5, scheduler: q)
            .print(debugDescription)
            .sink { someValue in
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedCount += 1
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print(msTime.string(from: Date()) + "Updating to foo.intValue on background queue")
            foo.intValue = 1
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print(msTime.string(from: Date()) + "Updating to foo.intValue on background queue")
            foo.intValue = 2
        }
        q.asyncAfter(deadline: .now() + 0.3) {
            print(msTime.string(from: Date()) + "Updating to foo.intValue on background queue")
            foo.intValue = 3
        }

        q.asyncAfter(deadline: .now() + 1) {
            print(msTime.string(from: Date()) + "Updating to foo.intValue on background queue")
            foo.intValue = 10
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedCount, 2)
        XCTAssertEqual(foo.intValue, 10)
        XCTAssertNotNil(cancellable)
    }

    func testThrottleLatestFalse() {
        // NOTE(heckj): test is flaky in terms of it's timing, and repeated invocations are returning variable results
        let msTime = DateFormatter()
        msTime.dateFormat = "[HH:mm:ss.SSSS] "

        // Would'a been cool - but DateComponentsFormatter is limited to "seconds" - doesn't do sub-second display
        // let intervalFormatter = DateComponentsFormatter()
        // intervalFormatter.allowedUnits = [.second,.nanosecond]
        // intervalFormatter.allowsFractionalUnits = true
        // intervalFormatter.unitsStyle = .positional
        // intervalFormatter.includesTimeRemainingPhrase = true

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let start_mark = Date()
        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(debugDescription)
            .sink { someValue in
                print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
                print(msTime.string(from: Date()) + "sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 1 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 1
            // this value is collapsed by the throttle and not passed through to sink
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 2 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 2
            // this value is collapsed by the throttle and not passed through to sink
        }
        q.asyncAfter(deadline: .now() + 0.6) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 3 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 3
        }
        q.asyncAfter(deadline: .now() + 0.7) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 4 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 4
            // this value is collapsed by the throttle and not passed through to sink
        }

        q.asyncAfter(deadline: .now() + 0.9) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 5 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 5
        }

        q.asyncAfter(deadline: .now() + 1.2) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 6 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
            // this value is collapsed by the throttle and not passed through to sink
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)

        // NOTE(heckj): this changed in Xcode 11.2 (iOS 13.2):
        // of the values sent at 1.1 and 1.2 seconds in, the second value is returned down the pipeline
        // and prior to that it returned the first value - so the value of "false" for recent from throttle
        // doesn't appear to be respected. - reported as FB7424221
        //
        // This updated again in Xcode 11.3 (iOS 13.3), and now throttle(true) and throttle(false) exhibit
        // different behavior again.
        //
        // XCTAssertEqual(receivedList, [-1, 5, 6]) // iOS 13.2.2
        // XCTAssertEqual(receivedList, [-1, 3, 5]) // iOS 13.3 - flaky response
        // XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.4
        XCTAssertEqual(receivedList, [-1, 1, 3, 6]) // iOS 14.1
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }

    func testThrottleLatestTrue() {
        let msTime = DateFormatter()
        msTime.dateFormat = "[HH:mm:ss.SSSS] "

        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let start_mark = Date()
        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(debugDescription)
            .sink { someValue in
                print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 1 on background queue")
            foo.intValue = 1
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 2 on background queue")
            foo.intValue = 2
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.6) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 3 on background queue")
            foo.intValue = 3
        }
        q.asyncAfter(deadline: .now() + 0.7) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 4 on background queue")
            foo.intValue = 4
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.9) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 5 on background queue")
            foo.intValue = 5
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 6 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)
        // The values sent at 0.1 and 0.2 seconds in get collapsed, being within the 0.5 sec window
        // and requesting just the "latest" value - so the total number of events received by the sink
        // is fewer than the number sent.
        // XCTAssertEqual(receivedList, [2, 5, 6]) // iOS 13.2.2
//        XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.3
        XCTAssertEqual(receivedList, [-1, 2, 5, 6]) // iOS 14.1
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }

    func SKIP_testSubjectThrottleLatestAtWindowFalse() {
        // I'm setting this test to generally skip, since it's not going to consistently run
        // in the same fashion under CI as it does on my laptop. Since I'm pushing out values
        // right at the edge of the timing window in this test case, the results are hyper-sensitive
        // to slightly slower systems (such as VMs as in the CI system)

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(debugDescription)
            .sink { someValue in
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(2)
            // this value is collapsed by the throttle and not passed through to sink
        }
        q.asyncAfter(deadline: .now() + 0.6) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(3)
            // this value is collapsed by the throttle and not passed through to sink
        }
        q.asyncAfter(deadline: .now() + 0.7) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4)
        }
        q.asyncAfter(deadline: .now() + 1.1) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(5)
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
            // this value is collapsed by the throttle and not passed through to sink
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

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
        // XCTAssertEqual(receivedList, [3, 5]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 4, 5]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func SKIP_testSubjectThrottleLatestAtWindowTrue() {
        // I'm setting this test to generally skip, since it's not going to consistently run
        // in the same fashion under CI as it does on my laptop. Since I'm pushing out values
        // right at the edge of the timing window in this test case, the results are hyper-sensitive
        // to slightly slower systems (such as VMs as in the CI system)

        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.6) {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.7) {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        }
        q.asyncAfter(deadline: .now() + 1.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 3)
        // The values sent at 0.1 and 0.2 seconds in get collapsed, being within the 0.5 sec window
        // and requesting just the "latest" value - so the total number of events received by the sink
        // is fewer than the number sent.
        // XCTAssertEqual(receivedList, [3, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 4, 6]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    // getting inconsistent results from this in CI testing, due to underlying timing.
    // need to re-create these tests with something (Entwine?) that isn't impacted by
    // underlying system-specific loading & timing
    func SKIP_testSpreadoutSubjectThrottleLatestFalse() {
        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        print("testing queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(debugDescription)
            .sink { someValue in
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(2)
        }
        q.asyncAfter(deadline: .now() + 0.8) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(3)
        }
        q.asyncAfter(deadline: .now() + 0.9) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4)
            // this value is collapsed by the throttle and not passed through to sink
        }
        q.asyncAfter(deadline: .now() + 1.5) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(5)
        }
        q.asyncAfter(deadline: .now() + 1.6) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
            // this value is collapsed by the throttle and not passed through to sink
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)
        // XCTAssertEqual(receivedList, [1, 3, 5]) // iOS 13.2.2
        // XCTAssertEqual(receivedList, [1, 2, 3, 5]) // iOS 13.3
        XCTAssertEqual(receivedList, [1, 2, 3, 6]) // iOS 14.1 locally
        XCTAssertNotNil(cancellable)
    }

    func testSpreadoutSubjectThrottleLatestTrue() {
        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
        }
        q.asyncAfter(deadline: .now() + 0.8) {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.9) {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        }
        q.asyncAfter(deadline: .now() + 1.5) {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 1.6) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedList.count, 4)
        // XCTAssertEqual(receivedList, [2, 4, 6]) // iOS 13.2.2
        XCTAssertEqual(receivedList, [1, 2, 4, 6]) // iOS 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSubjectDebounce() {
        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .debounce(for: 0.5, scheduler: q)
            .print(debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        // this is the same timing pattern as the throttle tests above, for comparison
        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.6) {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.7) {
            print("Updating to foo.intValue on background queue")
            foo.send(4)
        }
        q.asyncAfter(deadline: .now() + 1.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(5)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(6)
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedList, [6]) // iOS 13.2.2 and 13.3
        XCTAssertNotNil(cancellable)
    }

    func testSubjectDebounceWithBreak() {
        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)
        var receivedList: [Int] = []

        let cancellable = foo
            .debounce(for: 0.5, scheduler: q)
            .print(debugDescription)
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(1)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("Updating to foo.intValue on background queue")
            foo.send(2)
        }
        q.asyncAfter(deadline: .now() + 1.1) {
            print("Updating to foo.intValue on background queue")
            foo.send(3)
            // this value gets collapsed and not propagated
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("Updating to foo.intValue on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4)
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedList, [2, 4]) // iOS 13.2.2 and 13.3
        XCTAssertNotNil(cancellable)
    }
}
