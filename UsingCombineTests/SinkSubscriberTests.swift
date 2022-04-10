//
//  UsingCombineTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/3/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class SinkSubscriberTests: XCTestCase {
    func testSimpleSink() {
        // setup
        let expectation = XCTestExpectation(description: "async sink test")
        let examplePublisher = Just(5)
        // validate
        let cancellable = examplePublisher.sink { value in
            print(".sink() received \(String(describing: value))")
            XCTAssertEqual(value, 5)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testDualSink() {
        // setup
        let expectation = XCTestExpectation(description: "async sink test")
        let examplePublisher = Just(5)

        // validate
        let cancellable = examplePublisher.sink(receiveCompletion: { err in
            print(".sink() received the completion", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received \(String(describing: value))")
            XCTAssertEqual(value, 5)
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testSinkReceiveDataThenError() {
        // setup - preconditions
        let expectedValues = ["firstStringValue", "secondStringValue"]
        enum TestFailureCondition: Error {
            case anErrorExample
        }
        var countValuesReceived = 0
        var countCompletionsReceived = 0
        // setup
        let simplePublisher = PassthroughSubject<String, Error>()

        let cancellable = simplePublisher
            .sink(receiveCompletion: { completion in
                countCompletionsReceived += 1
                switch completion {
                case .finished:
                    print(".sink() received the completion:", String(describing: completion))
                    // no associated data, but you can react to knowing the request has been completed
                    XCTFail("We should never receive the completion, because the error should happen first")
                case let .failure(anError):
                    // do what you want with the error details, presenting, logging, or hiding as appropriate
                    print("received the error: ", anError)
                    XCTAssertEqual(anError.localizedDescription,
                                   TestFailureCondition.anErrorExample.localizedDescription)
                }
            }, receiveValue: { someValue in
                // do what you want with the resulting value passed down
                // be aware that depending on the data type being returned, you may get this closure invoked
                // multiple times.
                XCTAssertNotNil(someValue)
                XCTAssertTrue(expectedValues.contains(someValue))
                countValuesReceived += 1
                print(".sink() received \(someValue)")
            })

        // validate
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(countValuesReceived, 0)
        XCTAssertEqual(countCompletionsReceived, 0)

        simplePublisher.send("firstStringValue")
        XCTAssertEqual(countValuesReceived, 1)
        XCTAssertEqual(countCompletionsReceived, 0)

        simplePublisher.send("secondStringValue")
        XCTAssertEqual(countValuesReceived, 2)
        XCTAssertEqual(countCompletionsReceived, 0)

        simplePublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.anErrorExample))
        XCTAssertEqual(countValuesReceived, 2)
        XCTAssertEqual(countCompletionsReceived, 1)

        // this data will never be seen by anything in the pipeline above because we've already sent a completion
        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(countValuesReceived, 2)
        XCTAssertEqual(countCompletionsReceived, 1)
    }

    func testSinkReceiveDataThenCancelled() {
        // setup - preconditions
        let expectedValues = ["firstStringValue"]
        var countValuesReceived = 0
        var countCompletionsReceived = 0
        // setup
        let simplePublisher = PassthroughSubject<String, Error>()

        let cancellablePipeline = simplePublisher
            .sink(receiveCompletion: { completion in
                countCompletionsReceived += 1
                switch completion {
                case .finished:
                    print(".sink() received the completion:", String(describing: completion))
                    // no associated data, but you can react to knowing the request has been completed
                    XCTFail("We should never receive the completion, because the cancel should happen first")
                case let .failure(anError):
                    // do what you want with the error details, presenting, logging, or hiding as appropriate
                    print("received the error: ", anError)
                    XCTFail("We should never receive the completion, because the cancel should happen first")
                }
            }, receiveValue: { someValue in
                // do what you want with the resulting value passed down
                // be aware that depending on the data type being returned, you may get this closure invoked
                // multiple times.
                XCTAssertNotNil(someValue)
                XCTAssertTrue(expectedValues.contains(someValue))
                countValuesReceived += 1
                print(".sink() received \(someValue)")
            })

        // validate
        XCTAssertEqual(countValuesReceived, 0)
        XCTAssertEqual(countCompletionsReceived, 0)

        simplePublisher.send("firstStringValue")
        XCTAssertEqual(countValuesReceived, 1)
        XCTAssertEqual(countCompletionsReceived, 0)

        cancellablePipeline.cancel()
        // the pipeline doesn't process anything after the cancel, either values or completions

        simplePublisher.send("secondStringValue")
        XCTAssertEqual(countValuesReceived, 1)
        XCTAssertEqual(countCompletionsReceived, 0)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(countValuesReceived, 1)
        XCTAssertEqual(countCompletionsReceived, 0)
    }
}
