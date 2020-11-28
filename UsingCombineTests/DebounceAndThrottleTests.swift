//
//  DebounceAndThrottleTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 11/27/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import CombineSchedulers
import XCTest

class DebounceAndThrottleTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func testDebounce() {
        let testScheduler = DispatchQueue.testScheduler

        let msTime = DateFormatter()
        msTime.dateFormat = "[HH:mm:ss.SSSS] "

        class HoldingClass: ObservableObject {
            @Published var intValue: Int = -1
        }

        let foo = HoldingClass()
        var receivedCount = 0
        var receivedValue: Int?

        foo.$intValue
            .debounce(for: 0.5, scheduler: testScheduler)
            .print(self.debugDescription)
            .sink { someValue in
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedCount += 1
                receivedValue = someValue
            }
            .store(in: &self.cancellables)

        // 0 ms
        // nothing received until the debounce time
        // (500ms) has elapsed between values changing
        XCTAssertEqual(receivedCount, 0)
        XCTAssertNil(receivedValue)
        testScheduler.advance(by: .milliseconds(100))
        foo.intValue = 1

        // 100 ms
        // nothing received until the debounce time
        // (500ms) has elapsed between values changing
        testScheduler.advance(by: .milliseconds(100))
        foo.intValue = 2
        XCTAssertEqual(receivedCount, 0)
        XCTAssertNil(receivedValue)

        // 300 ms
        // nothing received until the debounce time
        // (500ms) has elapsed between values changing
        testScheduler.advance(by: .milliseconds(100))
        foo.intValue = 3
        XCTAssertEqual(receivedCount, 0)
        XCTAssertEqual(foo.intValue, 3)
        XCTAssertNil(receivedValue)

        // 600 ms
        // nothing received until the debounce time
        // (500ms) has elapsed between values changing
        testScheduler.advance(by: .milliseconds(300))
        XCTAssertEqual(receivedCount, 0)
        XCTAssertNil(receivedValue)

        // 850 ms (+600ms since last change)
        testScheduler.advance(by: .milliseconds(250))
        XCTAssertEqual(receivedCount, 1)
        XCTAssertNotNil(receivedValue)
        XCTAssertEqual(receivedValue, 3)

        foo.intValue = 5
        testScheduler.advance(by: .milliseconds(1))
        foo.intValue = 6
        testScheduler.advance(by: .milliseconds(1))
        foo.intValue = 7
        testScheduler.advance(by: .milliseconds(1))

        testScheduler.advance(by: .milliseconds(500))
        XCTAssertEqual(receivedCount, 2)
        XCTAssertEqual(receivedValue, 7)
    }

    // TESTS TO REWRITE WITH NEW TEST SCHEDULER SETUP

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

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: false)
            .print(self.debugDescription)
            .sink { someValue in
                print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
                print(msTime.string(from: Date()) + "sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 1 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 1
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 2 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 2
            // this value is collapsed by the throttle and not passed through to sink
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 3 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 3
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 4 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 4
            // this value is collapsed by the throttle and not passed through to sink
        })

        q.asyncAfter(deadline: .now() + 0.9, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 5 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 5
        })

        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating foo.intValue to 6 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
            // this value is collapsed by the throttle and not passed through to sink
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

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
        //XCTAssertEqual(receivedList, [-1, 5, 6]) // iOS 13.2.2
        //XCTAssertEqual(receivedList, [-1, 3, 5]) // iOS 13.3 - flaky response
        //XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.4
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

        let q = DispatchQueue(label: self.debugDescription)
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: q, latest: true)
            .print(self.debugDescription)
            .sink { someValue in
                print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
                print(msTime.string(from: Date()) + "value updated to: ", someValue)
                receivedList.append(someValue)
        }

        q.asyncAfter(deadline: .now() + 0.1, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 1 on background queue")
            foo.intValue = 1
            // this value gets collapsed and not propagated
        })
        q.asyncAfter(deadline: .now() + 0.2, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 2 on background queue")
            foo.intValue = 2
            // this value gets collapsed and not propagated
        })
        q.asyncAfter(deadline: .now() + 0.6, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 3 on background queue")
            foo.intValue = 3
        })
        q.asyncAfter(deadline: .now() + 0.7, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 4 on background queue")
            foo.intValue = 4
            // this value gets collapsed and not propagated
        })
        q.asyncAfter(deadline: .now() + 0.9, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 5 on background queue")
            foo.intValue = 5
            // this value gets collapsed and not propagated
        })
        q.asyncAfter(deadline: .now() + 1.2, execute: {
            print("T-\(Date().timeIntervalSince(start_mark).toReadableString())")
            print(msTime.string(from: Date()) + "Updating to foo.intValue to 6 on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.intValue = 6
        })

        q.asyncAfter(deadline: .now() + 3, execute: {
            expectation.fulfill()
        })

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
}
