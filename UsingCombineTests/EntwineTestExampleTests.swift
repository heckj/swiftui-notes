//
//  EntwineTestExampleTests.swift
//  UsingCombineTests
//
//  Originally from the EntwineTest project README:
//  https://github.com/tcldr/Entwine/blob/master/Assets/EntwineTest/README.md

import Combine
import EntwineTest
// library loaded from https://github.com/tcldr/Entwine/blob/master/Assets/EntwineTest/README.md
// as a swift package https://github.com/tcldr/Entwine.git : 0.6.0, Next Major Version
import XCTest

class EntwineTestExampleTests: XCTestCase {
    func testMap() {
        let testScheduler = TestScheduler(initialClock: 0)

        // creates a publisher that will schedule its elements relatively, at the point of subscription
        let testablePublisher: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (300, .input("c")),
        ])

        // a publisher that maps strings to uppercase
        let subjectUnderTest = testablePublisher.map { $0.uppercased() }

        // uses the method described above (schedules a subscription at 200, to be cancelled at 900)
        let results = testScheduler.start { subjectUnderTest }

        XCTAssertEqual(results.recordedOutput, [
            (200, .subscription), // subscribed at 200
            (300, .input("A")), // received uppercased input @ 100 + subscription time
            (400, .input("B")), // received uppercased input @ 200 + subscription time
            (500, .input("C")), // received uppercased input @ 300 + subscription time
        ])
    }

    func testExampleUsingVirtualTimeScheduler() {
        let scheduler = TestScheduler(initialClock: 0)
        var didSink = false
        let cancellable = Just(1)
            .delay(for: 1, scheduler: scheduler)
            .sink { _ in
                didSink = true
            }

        XCTAssertNotNil(cancellable)
        // where a real scheduler would have triggered when .sink() was invoked
        // the virtual time scheduler requires resume() to commence and runs to
        // completion.
        scheduler.resume()
        XCTAssertTrue(didSink)
    }
}
