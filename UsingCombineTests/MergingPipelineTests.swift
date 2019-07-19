//
//  MergingPipelineTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/19/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import EntwineTest
// library loaded from https://github.com/tcldr/Entwine/blob/master/Assets/EntwineTest/README.md
// as a swift package https://github.com/tcldr/Entwine.git : 0.6.0, Next Major Version
import XCTest

class MergingPipelineTests: XCTestCase {

    // tests for combineLatest, merge, and zip
    func testCombineLatest() {
        // setup
        let testScheduler = TestScheduler(initialClock: 0)

        // set up the inputs and timing
        let testablePublisher1: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (350, .input("c")),
        ])
        let testablePublisher2: TestablePublisher<Int, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input(1)),
            (250, .input(2)),
            (300, .input(3)),
        ])

        let merged = Publishers.CombineLatest(testablePublisher1, testablePublisher2)

        // validate

        // run the virtual time scheduler
        let testableSubscriber = testScheduler.start { return merged }

        // check the collected results
        XCTAssertEqual(testableSubscriber.recordedOutput.count, 6)

        print(testableSubscriber.recordedOutput)
        // TestSequence<(String, Int), Never>(contents: [(200, .subscribe), (300, .input(("a", 1))), (400, .input(("b", 1))), (450, .input(("b", 2))), (500, .input(("b", 3))), (550, .input(("c", 3)))])

        let firstInSequence = testableSubscriber.recordedOutput[0]
        XCTAssertEqual(firstInSequence.0, 200) // checks the virtualtime of the subscription
        // which is always expected to be 200 with this scheduled

        // filter the output signals down to just the inputs - drop any subscriptions, cancel, or completions
        let outputSignals = testableSubscriber.recordedOutput.filter { time, signal -> Bool in
            // input type is (VirtualTime, Signal<(String, Int), Never>)
            switch signal {
            case .input(_, _):
                return true
            default:
                return false
            }
        }
        XCTAssertEqual(outputSignals.count, 5)
        print(outputSignals)
        // TestSequence<(String, Int), Never>(contents: [(300, .input(("a", 1))), (400, .input(("b", 1))), (450, .input(("b", 2))), (500, .input(("b", 3))), (550, .input(("c", 3)))])

//        let foo = outputSignals[0]
        //XCTAssertEqual(foo, .input(("a", 1))) // not equatable, so the compiler blows this up...
        /*
         Global function 'XCTAssertEqual(_:_:_:file:line:)' requires that '(VirtualTime, Signal<(String, Int), Never>)' conform to 'Equatable'
         */

        let expectedSequence = TestSequence<(String, Int), Never>([
            (300, .input(("a", 1))),
            (400, .input(("b", 1))),
            (450, .input(("b", 2))),
            (500, .input(("b", 3))),
            (550, .input(("c", 3)))
        ])

        // XCTAssertEqual(outputSignals, expectedSequence) // compiler error
        /*
         Global function 'XCTAssertEqual(_:_:_:file:line:)' requires that '(String, Int)' conform to 'Equatable'
         -> Requirement from conditional conformance of 'TestSequence<(String, Int), Never>' to 'Equatable' (EntwineTest.TestSequence<τ_0_0, τ_0_1>)
         */


    }
}
