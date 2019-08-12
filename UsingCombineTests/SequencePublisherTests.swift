//
//  SequencePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class SequencePublisherTests: XCTestCase {

    func testSequencePublisher() {
        let expectation = XCTestExpectation(description: self.debugDescription)

        let initialSequence = ["one", "two", "red", "blue"]

        var receiveCount = 0
        var collectedSequence: [String] = []

        let cancellable = Publishers.Sequence<[String], Never>(sequence: initialSequence)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case .failure(let anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                    break
                }
                expectation.fulfill()
            }, receiveValue: { valueReceived in
                receiveCount += 1
                collectedSequence.append(valueReceived)
                print(".sink() data received \(valueReceived)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(receiveCount, 4)
        XCTAssertEqual(collectedSequence, initialSequence)
    }

    func testSequencePublisherOptionalType() {
        let expectation = XCTestExpectation(description: self.debugDescription)

        let initialSequence = ["one", "two", nil, "red", "blue"]

        var receiveCount = 0
        var collectedSequence: [String?] = []

        let cancellable = Publishers.Sequence<[String?], Never>(sequence: initialSequence)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case .failure(let anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                    break
                }
                expectation.fulfill()
            }, receiveValue: { valueReceived in
                receiveCount += 1
                collectedSequence.append(valueReceived)
                print(".sink() data received \(String(describing: valueReceived))")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(receiveCount, 5)
        XCTAssertEqual(collectedSequence, initialSequence)
    }
}
