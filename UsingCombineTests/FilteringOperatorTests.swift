//
//  FilteringOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/15/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class FilteringOperatorTests: XCTestCase {
    enum TestExampleError: Error {
        case example
    }

    func testReplaceNil() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String] = []

        let cancellable = passSubj
            .print(debugDescription)
            .replaceNil(with: "-replacement-")
            .sink { someValue in
                print("value updated to: ", someValue)
                receivedList.append(someValue)
            }

        passSubj.send("one")
        passSubj.send(nil)
        passSubj.send("")
        passSubj.send(nil)
        passSubj.send("five")
        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertEqual(receivedList, ["one", "-replacement-", "", "-replacement-", "five"])
        XCTAssertNotNil(cancellable)
    }

    func testReplaceEmptyWithValues() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String?] = []

        let cancellable = passSubj
            .print(debugDescription)
            .replaceEmpty(with: "-replacement-")
            .sink { someValue in
                print("value updated to: ", someValue as Any)
                receivedList.append(someValue)
            }

        passSubj.send("one")
        passSubj.send(nil)
        passSubj.send("")
        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertEqual(receivedList, ["one", nil, ""])
        XCTAssertNotNil(cancellable)
    }

    func testReplaceEmptyNoValues() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String?] = []

        let cancellable = passSubj
            .print(debugDescription)
            .replaceEmpty(with: "-replacement-")
            .sink { someValue in
                print("value updated to: ", someValue as Any)
                receivedList.append(someValue)
            }

        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertEqual(receivedList, ["-replacement-"])
        XCTAssertNotNil(cancellable)
    }

    func testReplaceEmptyWithFailure() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String] = []

        let cancellable = passSubj
            .print(debugDescription)
            .replaceEmpty(with: "-replacement-")
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                receivedList.append(responseValue)
                XCTFail()
            })

        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.example))

        XCTAssertEqual(receivedList, [])
        XCTAssertNotNil(cancellable)
    }

    func testCompactMap() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String] = []

        let cancellable = passSubj
            .print(debugDescription)
            .compactMap {
                $0
            }
            .sink { someValue in
                print("value updated to: ", someValue as Any)
                receivedList.append(someValue)
            }

        passSubj.send("one")
        passSubj.send(nil)
        passSubj.send("")
        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertEqual(receivedList, ["one", ""])
        XCTAssertNotNil(cancellable)
    }

    func testTryCompactMap() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var receivedList: [String] = []

        let cancellable = passSubj
            .tryCompactMap { someVal -> String? in
                if someVal == "boom" {
                    throw TestExampleError.example
                }
                return someVal
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                receivedList.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        passSubj.send("one")
        passSubj.send(nil)
        passSubj.send("")
        passSubj.send("boom")
        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertEqual(receivedList, ["one", ""])
        XCTAssertNotNil(cancellable)
    }
}
