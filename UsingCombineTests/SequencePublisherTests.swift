//
//  SequencePublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class SequencePublisherTests: XCTestCase {
    func testSequencePublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let initialSequence = ["one", "two", "red", "blue"]

        var receiveCount = 0
        var collectedSequence: [String] = []

        let cancellable = Publishers.Sequence<[String], Never>(sequence: initialSequence)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
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
        let expectation = XCTestExpectation(description: debugDescription)

        let initialSequence = ["one", "two", nil, "red", "blue"]

        var receiveCount = 0
        var collectedSequence: [String?] = []

        let cancellable = Publishers.Sequence<[String?], Never>(sequence: initialSequence)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
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

    func testConvenienceArraySequencePublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let initialSequence = ["one", "two", "red", "blue"]

        var receiveCount = 0
        var collectedSequence: [String] = []

        _ = initialSequence.publisher
            .sink {
                print($0)
            }

        let cancellable = initialSequence.publisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
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

    func testConvenienceMapSequencePublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let associativeArray: [String: String] = ["one": "two", "red": "blue"]

        var receiveCount = 0
        var collectedSequence: [(String, String)] = []

        let cancellable = associativeArray.publisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { valueReceived in
                receiveCount += 1
                collectedSequence.append(valueReceived)
                print(".sink() data received \(valueReceived)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(receiveCount, 2)
        // ordering is not guaranteed...
//        XCTAssertEqual(collectedSequence[0].0, "one")
//        XCTAssertEqual(collectedSequence[0].1, "two")
//        XCTAssertEqual(collectedSequence[1].0, "red")
//        XCTAssertEqual(collectedSequence[1].1, "blue")
    }
}
