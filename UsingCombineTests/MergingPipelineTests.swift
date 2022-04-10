//
//  MergingPipelineTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/19/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import Entwine // to get access to Signal as a public enum
import EntwineTest
// library loaded from https://github.com/tcldr/Entwine/blob/master/Assets/EntwineTest/README.md
// as a swift package https://github.com/tcldr/Entwine.git : 0.6.0, Next Major Version
import XCTest

class MergingPipelineTests: XCTestCase {
    // since I'm screwed on using the built in equatable with a tuple response type from the operator I'm testing
    // we'll make a one-off checking function to validate the expected virtualtime and resulting values all match up.
    // Global function 'XCTAssertEqual(_:_:_:file:line:)' requires that '(VirtualTime, Signal<(String, Int), Never>)' conform to 'Equatable'
    func testSequenceMatch<T0, T1, F0>(sequenceItem: (VirtualTime, Signal<(T0, T1), F0>),
                                       time: VirtualTime,
                                       inputvalues: (T0, T1)) -> Bool
    {
        if sequenceItem.0 != time {
            return false
        }
        if sequenceItem.1.debugDescription != Signal<(T0, T1), F0>.input(inputvalues).debugDescription {
            return false
        }
        return true
    }

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
        let testableSubscriber = testScheduler.start { merged }

        // check the collected results
        XCTAssertEqual(testableSubscriber.recordedOutput.count, 6)

        // print(testableSubscriber.recordedOutput)
        // TestSequence<(String, Int), Never>(contents: [(200, .subscribe), (300, .input(("a", 1))), (400, .input(("b", 1))), (450, .input(("b", 2))), (500, .input(("b", 3))), (550, .input(("c", 3)))])

        let firstInSequence = testableSubscriber.recordedOutput[0]
        XCTAssertEqual(firstInSequence.0, 200) // checks the virtualtime of the subscription
        // which is always expected to be 200 with this scheduled

        // filter the output signals down to just the inputs - drop any subscriptions, cancel, or completions
        let outputSignals = testableSubscriber.recordedOutput.filter { _, signal -> Bool in
            // input type is (VirtualTime, Signal<(String, Int), Never>)
            switch signal {
            case .input((_, _)):
                return true
            default:
                return false
            }
        }
        XCTAssertEqual(outputSignals.count, 5)
        // print(outputSignals)
        // TestSequence<(String, Int), Never>(contents: [(300, .input(("a", 1))), (400, .input(("b", 1))), (450, .input(("b", 2))), (500, .input(("b", 3))), (550, .input(("c", 3)))])

        // NOTE(heckj) - well this is an ugly hack, but it works
        // normally an Entwine Signal would be equatable because the enumeration includes equatable conformance.
        // However, that equatable conformance relies on the underlying type being passed around to be equatable.
        // When we're working with one of this operators that merge streams, the output type in question is a
        // tuple, which can not provide equatable conformance.
        // Swift tuples aren't allowed to conform to protocols, which means they can't ever be equatable.
        // the hack that I'm using to get around this conformance ick is utilizing debugDescription to create a
        // string from the Signal reference, and then comparing that to a Signal instance created as the expected
        // value.
        _ = outputSignals[0] // a tuple instance of (VirtualTime, Signal<(String, Int)>)
        _ = outputSignals[0].1 // the signal itself: type Signal<(String, Int)>)
        let foo = outputSignals[0].1.debugDescription // converts the signal into a string using debugDescription
        let expected = Signal<(String, Int), Never>.input(("a", 1)).debugDescription
        XCTAssertEqual(foo, expected)

        XCTAssertTrue(
            testSequenceMatch(sequenceItem: outputSignals[0], time: 300, inputvalues: ("a", 1))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: outputSignals[1], time: 400, inputvalues: ("b", 1))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: outputSignals[2], time: 450, inputvalues: ("b", 2))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: outputSignals[3], time: 500, inputvalues: ("b", 3))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: outputSignals[4], time: 550, inputvalues: ("c", 3))
        )

        // In hindsight, I don't know that I really care about the timing of all these results, aside
        // from the fact that it makes for an illuminating record of how combineLatest() itself
        // functions.
    }

    func testCombineLatestWithFailure() {
        // setup
        enum TestFailureCondition: Error {
            case example
        }

        let testScheduler = TestScheduler(initialClock: 0)

        // set up the inputs and timing
        let testablePublisher1: TestablePublisher<String, Error> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (350, .input("c")),
            (400, .completion(.failure(TestFailureCondition.example))),
        ])
        let testablePublisher2: TestablePublisher<Int, Error> = testScheduler.createRelativeTestablePublisher([
            (100, .input(1)),
            (250, .input(2)),
            (300, .input(3)),
            (450, .input(4)),
        ])

        let merged = Publishers.CombineLatest(testablePublisher1, testablePublisher2)

        // validate

        // run the virtual time scheduler
        let testableSubscriber = testScheduler.start { merged }

        // check the collected results
        XCTAssertEqual(testableSubscriber.recordedOutput.count, 7)
        print(testableSubscriber.recordedOutput)

//        TestSequence<(String, Int), Error>(contents:
//            [(200, .subscribe),
//             (300, .input(("a", 1))),
//             (400, .input(("b", 1))),
//             (450, .input(("b", 2))),
//             (500, .input(("b", 3))),
//             (550, .input(("c", 3))),
//             (600, .completion(failure(UsingCombineTests.MergingPipelineTests.(unknown context at $108734d68).(unknown context at $108734dd8).TestFailureCondition.example)))
//        terminating one of the streams completing with .failure terminates all of the pipeline
//            ])

        // verify the virtual time of the subscription signal
        XCTAssertEqual(testableSubscriber.recordedOutput[0].0, 200)
        // verify that the first signal was a subscription
        XCTAssertEqual(testableSubscriber.recordedOutput[0].1.debugDescription, ".subscribe")

        XCTAssertTrue(
            testSequenceMatch(sequenceItem: testableSubscriber.recordedOutput[1], time: 300, inputvalues: ("a", 1))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: testableSubscriber.recordedOutput[2], time: 400, inputvalues: ("b", 1))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: testableSubscriber.recordedOutput[3], time: 450, inputvalues: ("b", 2))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: testableSubscriber.recordedOutput[4], time: 500, inputvalues: ("b", 3))
        )
        XCTAssertTrue(
            testSequenceMatch(sequenceItem: testableSubscriber.recordedOutput[5], time: 550, inputvalues: ("c", 3))
        )

        // verify the virtual time of the completion signal
        XCTAssertEqual(testableSubscriber.recordedOutput[6].0, 600)
        // verify that the final signal was a completion
        XCTAssertTrue(testableSubscriber.recordedOutput[6].1.isCompletion)
    }

    func testCombineLatest3() {
        // setup
        let testScheduler = TestScheduler(initialClock: 0)

        // set up the inputs and timing
        let testablePublisher1: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (350, .input("c")),
            (400, .completion(.finished)),
        ])
        let testablePublisher2: TestablePublisher<Int, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input(1)),
            (250, .input(2)),
            (300, .input(3)),
            (450, .input(4)),
        ])
        let testablePublisher3: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("x")),
            (200, .input("y")),
            (350, .input("z")),
        ])

        let mergedPipeline = Publishers.CombineLatest3(testablePublisher1, testablePublisher2, testablePublisher3)

        // validate

        // run the virtual time scheduler
        let testableSubscriber = testScheduler.start { mergedPipeline }

        let expected: TestSequence<(String, Int, String), Never> = [
            (200, .subscription),
            (300, .input(("a", 1, "x"))),
            (400, .input(("b", 1, "x"))),
            (400, .input(("b", 1, "y"))),
            (450, .input(("b", 2, "y"))),
            (500, .input(("b", 3, "y"))),
            (550, .input(("c", 3, "y"))),
            (550, .input(("c", 3, "z"))),
            // pipeline 1 terminated at 600 - notice that we don't see an overall termination here due to that
            (650, .input(("c", 4, "z"))),
        ]
        // using the latest hotness of Entwine - post 0.6.0 release (part of master branch, as of 20 July 2019)
        // mapInput does the transformation from tuple to struct, with the struct's defined in
        // InterimTestingStructs.swift
        let mappedExpected = expected.mapInput(Tuple3.init)
        let mappedResults = testableSubscriber.recordedOutput.mapInput(Tuple3.init)
        XCTAssertEqual(mappedResults, mappedExpected)
    }

    func testZip() {
        // setup
        let testScheduler = TestScheduler(initialClock: 0)

        // set up the inputs and timing
        let testablePublisher1: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (350, .input("c")),
            (400, .completion(.finished)),
        ])
        let testablePublisher2: TestablePublisher<Int, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input(1)),
            (250, .input(2)),
            (300, .input(3)),
            (450, .input(4)),
        ])

        let mergedPipeline = Publishers.Zip(testablePublisher1, testablePublisher2)
        // validate

        // run the virtual time scheduler
        let testableSubscriber = testScheduler.start { mergedPipeline }

        print(testableSubscriber.recordedOutput)

        let expected: TestSequence<(String, Int), Never> = [
            (200, .subscription),
            (300, .input(("a", 1))),
            (450, .input(("b", 2))),
            (550, .input(("c", 3))),
            (600, .completion(.finished)),
        ]
        // using the latest hotness of Entwine - post 0.6.0 release (part of master branch, as of 20 July 2019)
        // mapInput does the transformation from tuple to struct, with the struct's defined in
        // InterimTestingStructs.swift
        let mappedExpected = expected.mapInput(Tuple2.init)
        let mappedResults = testableSubscriber.recordedOutput.mapInput(Tuple2.init)
        XCTAssertEqual(mappedResults, mappedExpected)
    }

    func testMerge() {
        // setup
        let testScheduler = TestScheduler(initialClock: 0)

        // set up the inputs and timing
        let testablePublisher1: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("a")),
            (200, .input("b")),
            (350, .input("c")),
            (400, .completion(.finished)),
        ])
        let testablePublisher2: TestablePublisher<String, Never> = testScheduler.createRelativeTestablePublisher([
            (100, .input("x")),
            (200, .input("y")),
            (300, .input("z")),
        ])

        let mergedPipeline = Publishers.Merge(testablePublisher1, testablePublisher2)
        // validate

        // run the virtual time scheduler
        let testableSubscriber = testScheduler.start { mergedPipeline }
        // print(testableSubscriber.recordedOutput)

        let expected: TestSequence<String, Never> = [
            (200, .subscription),
            (300, .input("a")),
            (300, .input("x")),
            (400, .input("b")),
            (400, .input("y")),
            (500, .input("z")),
            (550, .input("c")),
        ]
        XCTAssertEqual(testableSubscriber.recordedOutput, expected)
    }
}
