//
//  FilterPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class FilterPublisherTests: XCTestCase {
    func testFilter() {
        let simplePublisher = PassthroughSubject<String, Error>()

        let cancellable = simplePublisher
            .filter { stringValue in
                stringValue == "onefish"
            }
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                case .finished:
                    break
                }
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
                XCTAssertEqual(stringValue, "onefish")
            })

        simplePublisher.send("onefish") // onefish will pass the filter
        simplePublisher.send("twofish") // twofish will not
        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testTryFilter() {
        enum TestFailure: Error {
            case boom
        }

        let simplePublisher = PassthroughSubject<String, Error>()

        let cancellable = simplePublisher
            .tryFilter { stringValue in
                if stringValue == "explode" {
                    throw TestFailure.boom
                }
                return stringValue == "onefish"
            }
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                case .finished:
                    XCTFail("test sequence should fail before receiving finished")
                }
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
                XCTAssertEqual(stringValue, "onefish")
            })

        simplePublisher.send("onefish") // onefish will pass the filter
        simplePublisher.send("twofish") // twofish will not
        simplePublisher.send("explode") // explode will trigger a failure
        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }
}
