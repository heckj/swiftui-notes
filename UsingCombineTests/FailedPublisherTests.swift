//
//  FailedPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class FailedPublisherTests: XCTestCase {
    enum TestFailureCondition: Error {
        case exampleFailure
    }

    func testFailPublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let cancellable = Fail<String, Error>(error: TestFailureCondition.exampleFailure)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("No finished should be received from empty")
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { responseValue in
                XCTFail("No vaue should be received from empty")
                print(".sink() data received \(responseValue)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }

    func testFailPublisherAltInitializer() {
        let expectation = XCTestExpectation(description: debugDescription)

        let cancellable = Fail(outputType: String.self, failure: TestFailureCondition.exampleFailure)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("No finished should be received from empty")
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { responseValue in
                XCTFail("No vaue should be received from empty")
                print(".sink() data received \(responseValue)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }

    func testSetFailureTypePublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let initialSequence = ["one", "two", "red", "blue"]

        let cancellable = initialSequence.publisher
            .setFailureType(to: TestFailureCondition.self)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }
}
