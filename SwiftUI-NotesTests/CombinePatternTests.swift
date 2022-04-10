//
//  CombinePatternTests.swift
//  SwiftUI-NotesTests
//
//  Created by Joseph Heck on 6/21/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class CombinePatternTests: XCTestCase {
    enum TestFailureCondition: Error {
        case invalidServerResponse
    }

    func testDeadSimpleChain() {
        let simplePublisher = PassthroughSubject<String, Error>()

        _ = simplePublisher
            .print()
            // the result of adding in .print() to this chain is the following additional console output
            //        receive subscription: (PassthroughSubject)
            //        request unlimited
            //        receive value: (firstStringValue)
            //        receive value: (secondStringValue)
            //        receive error: (invalidServerResponse)
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                // this print adds into the console output:
                //        .sink() received firstStringValue
                //        .sink() received secondStringValue
                //        .sink() caught the failure failure(SwiftUI_NotesTests.CombinePatternTests.TestFailureCondition.invalidServerResponse)
            })

        simplePublisher.send("firstStringValue")
        simplePublisher.send("secondStringValue")
        simplePublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))

        // this data will never be seen by anything in the pipeline above because we've already sent a completion
        simplePublisher.send(completion: Subscribers.Completion.finished)

        // the full console output from this test
//        receive subscription: (PassthroughSubject)
//        request unlimited
//        receive value: (firstStringValue)
//        .sink() received firstStringValue
//        receive value: (secondStringValue)
//        .sink() received secondStringValue
//        receive error: (invalidServerResponse)
//        .sink() caught the failure failure(SwiftUI_NotesTests.CombinePatternTests.TestFailureCondition.invalidServerResponse)
    }

    func testDeadSimpleChainAssertNoFailure() {
        let simplePublisher = PassthroughSubject<String, Error>()

        _ = simplePublisher
            .assertNoFailure("What could possibly go wrong?")
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
            })

        simplePublisher.send("oneValue")
        simplePublisher.send("twoValue")

        // uncomment this next line to see the failure mode:
        // simplePublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))
        simplePublisher.send(completion: .finished)
    }

    func testDeadSimpleChainCatch() {
        let simplePublisher = PassthroughSubject<String, Error>()

        _ = simplePublisher
            .catch { _ in
                // must return a Publisher
                Just("replacement value")
            }
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
            })

        simplePublisher.send("oneValue")
        simplePublisher.send("twoValue")
        simplePublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))
        simplePublisher.send("redValue")
        simplePublisher.send("blueValue")
        simplePublisher.send(completion: .finished)

        // the output of this test is:
        // .sink() received oneValue
        // .sink() received twoValue
        // .sink() received replacement value
        // .sink() received the completion: finished
        // NOTE(heckj) catch intercepts the whole chain and replaces it with what you return.
        // In this case, it's the Just convenience publisher, which in turn immediately sends a "finish" when it's done.
    }
}
