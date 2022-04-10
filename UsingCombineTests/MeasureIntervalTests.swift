//
//  MeasureIntervalTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/15/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class MeasureIntervalTests: XCTestCase {
    func testMeasureInterval() {
        let foo = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        let q = DispatchQueue(label: debugDescription)
        let expectation = XCTestExpectation(description: debugDescription)

        var receivedList: [DispatchQueue.SchedulerTimeType.Stride] = []

        let cancellable = foo
            .measureInterval(using: q) // DispatchQueue.SchedulerTimeType.Stride
            .print(debugDescription)
            .sink { someValue in
                print("Magniture updated to: ", someValue.magnitude, " interval: ", someValue.timeInterval)
                receivedList.append(someValue)
            }

        q.asyncAfter(deadline: .now() + 0.1) {
            print("sending value on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(1)
            // Stride received. Magniture updated to:  110454274  interval:  nanoseconds(110454274)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            print("sending value on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(2)
            // Stride received. Magniture updated to:  107415192  interval:  nanoseconds(107415192)
        }
        q.asyncAfter(deadline: .now() + 1.1) {
            print("sending value on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(3)
            // Stride received. Magniture updated to:  887884605  interval:  nanoseconds(887884605)
        }
        q.asyncAfter(deadline: .now() + 1.2) {
            print("sending value on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(4)
            // Stride received. Magniture updated to:  120933362  interval:  nanoseconds(120933362)
        }
        q.asyncAfter(deadline: .now() + 1.21) {
            print("sending value on queue", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            foo.send(5)
            // Stride received. Magniture updated to:  115129  interval:  nanoseconds(115129)
        }

        q.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedList.count, 5)
        XCTAssertNotNil(cancellable)
    }
}
