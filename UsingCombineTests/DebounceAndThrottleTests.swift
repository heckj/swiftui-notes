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
    let testScheduler = DispatchQueue.testScheduler
    let msTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "[HH:mm:ss.SSSS] "

        // Would'a been cool - but DateComponentsFormatter is limited to "seconds" - doesn't do sub-second display
        // let intervalFormatter = DateComponentsFormatter()
        // intervalFormatter.allowedUnits = [.second,.nanosecond]
        // intervalFormatter.allowsFractionalUnits = true
        // intervalFormatter.unitsStyle = .positional
        // intervalFormatter.includesTimeRemainingPhrase = true

        return formatter
    }()

    func testDebounce() {
        class HoldingClass: ObservableObject {
            @Published var intValue: Int = -1
        }

        let foo = HoldingClass()
        var receivedCount = 0
        var receivedValue: Int?

        foo.$intValue
            .debounce(for: 0.5, scheduler: testScheduler)
            .print(debugDescription)
            .sink { someValue in
                print("time mark: \(self.testScheduler.now)")
                receivedCount += 1
                receivedValue = someValue
            }
            .store(in: &cancellables)

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

    func testThrottleLatestFalse() {
        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: testScheduler, latest: false)
            .print(debugDescription)
            .sink { someValue in
                print("time mark: \(self.testScheduler.now)")
                receivedList.append(someValue)
            }

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 1

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 2
        // this value is collapsed by the throttle and not passed through to sink

        testScheduler.advance(by: .milliseconds(400))

        foo.intValue = 3

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 4
        // this value is collapsed by the throttle and not passed through to sink

        testScheduler.advance(by: .milliseconds(200))

        foo.intValue = 5
        // this value is collapsed by the throttle and not passed through to sink

        testScheduler.advance(by: .milliseconds(400))

        foo.intValue = 6

        testScheduler.advance(by: .milliseconds(400))

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
        XCTAssertEqual(receivedList, [-1, 1, 3, 6]) // iOS 14.1 - 14.4
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }

    func testThrottleLatestTrue() {
        class HoldingClass {
            @Published var intValue: Int = -1
        }

        let foo = HoldingClass()
        // watching the @Published object always starts with an initial value propagated of it's
        // value at the time of subscription

        var receivedList: [Int] = []

        let cancellable = foo.$intValue
            .throttle(for: 0.5, scheduler: testScheduler, latest: true)
            .print(debugDescription)
            .sink { someValue in
                print("time mark: \(self.testScheduler.now)")
                receivedList.append(someValue)
            }

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 1
        // this value gets collapsed and not propagated

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 2
        // this value gets collapsed and not propagated

        testScheduler.advance(by: .milliseconds(400))

        foo.intValue = 3

        testScheduler.advance(by: .milliseconds(100))

        foo.intValue = 4
        // this value gets collapsed and not propagated

        testScheduler.advance(by: .milliseconds(200))

        foo.intValue = 5
        // this value gets collapsed and not propagated

        testScheduler.advance(by: .milliseconds(300))

        foo.intValue = 6

        testScheduler.advance(by: .seconds(1))

        XCTAssertEqual(receivedList.count, 4)
        // The values sent at 0.1 and 0.2 seconds in get collapsed, being within the 0.5 sec window
        // and requesting just the "latest" value - so the total number of events received by the sink
        // is fewer than the number sent.
        // XCTAssertEqual(receivedList, [2, 5, 6]) // iOS 13.2.2
//        XCTAssertEqual(receivedList, [-1, 3, 6]) // iOS 13.3
        XCTAssertEqual(receivedList, [-1, 2, 5, 6]) // iOS 14.1 - 14.4
        XCTAssertEqual(foo.intValue, 6)
        XCTAssertNotNil(cancellable)
    }
}
