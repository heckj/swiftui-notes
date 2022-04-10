//
//  ScanPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/7/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class ScanPublisherTests: XCTestCase {
    func testScanInt() {
        let simplePublisher = PassthroughSubject<Int, Error>()

        var outputHolder = 0
        let cancellable = simplePublisher
            .scan(0) { a, b -> Int in
                a + b
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
            }, receiveValue: { receivedValue in
                print(".sink() received \(receivedValue)")
                outputHolder = receivedValue
            })

        simplePublisher.send(1)
        XCTAssertEqual(outputHolder, 1)

        simplePublisher.send(2)
        XCTAssertEqual(outputHolder, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(outputHolder, 3)
        XCTAssertNotNil(cancellable)
    }

    func testScanString() {
        let simplePublisher = PassthroughSubject<String, Error>()

        var outputHolder: String?
        let cancellable = simplePublisher
            .scan("") { a, b -> String in
                a + b
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
            }, receiveValue: { receivedValue in
                print(".sink() received \(receivedValue)")
                outputHolder = receivedValue
            })

        simplePublisher.send("a")
        XCTAssertEqual(outputHolder, "a")

        simplePublisher.send("b")
        XCTAssertEqual(outputHolder, "ab")

        simplePublisher.send("c")
        XCTAssertEqual(outputHolder, "abc")

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(outputHolder, "abc")
        XCTAssertNotNil(cancellable)
    }

    func testScanCounter() {
        let simplePublisher = PassthroughSubject<String, Error>()

        var outputHolder: Int?
        let cancellable = simplePublisher
            .scan(0) { prevVal, newValueFromPublisher -> Int in
                prevVal + newValueFromPublisher.count
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
            }, receiveValue: { receivedValue in
                print(".sink() received \(receivedValue)")
                outputHolder = receivedValue
            })

        simplePublisher.send("a")
        XCTAssertEqual(outputHolder, 1)

        simplePublisher.send("b")
        XCTAssertEqual(outputHolder, 2)

        simplePublisher.send("c")
        XCTAssertEqual(outputHolder, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(outputHolder, 3)
        XCTAssertNotNil(cancellable)
    }

    func testTryScanString() {
        enum TestFailure: Error {
            case boom
        }

        let simplePublisher = PassthroughSubject<String, Error>()

        var outputHolder: String?
        var erroredFromUpdates = false
        let cancellable = simplePublisher
            .tryScan("") { prevVal, newValueFromPublisher -> String in
                // this little bit of creative logic explicitly explodes if the combined
                // sequence that we accumulate is equal to 'ab'. We trigger this explicitly
                // from our test logic below to show the try aspect of tryScan
                if prevVal == "ab" {
                    throw TestFailure.boom
                }
                return prevVal + newValueFromPublisher
            }
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    erroredFromUpdates = true
                case .finished:
                    XCTFail() // this should never complete
                }
            }, receiveValue: { receivedValue in
                print(".sink() received \(receivedValue)")
                outputHolder = receivedValue
            })

        simplePublisher.send("a")
        XCTAssertEqual(outputHolder, "a")
        XCTAssertFalse(erroredFromUpdates)

        simplePublisher.send("b")
        XCTAssertEqual(outputHolder, "ab")
        XCTAssertFalse(erroredFromUpdates)

        // this send will trigger the error state and throw an exception within
        // the pipeline, so no further send() values will be used
        simplePublisher.send("c")
        XCTAssertEqual(outputHolder, "ab")
        XCTAssertTrue(erroredFromUpdates)

        simplePublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(outputHolder, "ab")
        XCTAssertNotNil(cancellable)
    }
}
