//
//  TimerPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/30/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class TimerPublisherTests: XCTestCase {
    func testTimerPublisherWithAutoconnect() {
        let expectation = XCTestExpectation(description: debugDescription)
        let q = DispatchQueue(label: debugDescription)
        var countOfReceivedEvents = 0

        let cancellable = Timer.publish(every: 1.0, on: RunLoop.main, in: .common)
            .autoconnect()
            .sink { receivedTimeStamp in
                // type is Date
                print("passed through: ", receivedTimeStamp)
                XCTAssertNotNil(receivedTimeStamp)
                countOfReceivedEvents += 1
            }

        q.asyncAfter(deadline: .now() + 3.4) {
            expectation.fulfill()
        }

        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(countOfReceivedEvents, 3)
    }

    func testTimerPublisherWithConnect() {
        let expectation = XCTestExpectation(description: debugDescription)
        let q = DispatchQueue(label: debugDescription)
        var countOfReceivedEvents = 0

        let timerPublisher = Timer.publish(every: 1.0, on: RunLoop.main, in: .common)
        let cancellable = timerPublisher
            .sink { receivedTimeStamp in
                print("passed through: ", receivedTimeStamp)
                XCTAssertNotNil(receivedTimeStamp)
                countOfReceivedEvents += 1
            }

        q.asyncAfter(deadline: .now() + 1.0) {
            let connectCancellable = timerPublisher.connect()
            XCTAssertNotNil(connectCancellable)
        }

        q.asyncAfter(deadline: .now() + 3.4) {
            expectation.fulfill()
        }

        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(countOfReceivedEvents, 2)
    }
}
