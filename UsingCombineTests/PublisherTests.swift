//
//  PublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/10/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class PublisherTests: XCTestCase {

    struct HoldingStruct {
        @Published var username: String = ""
    }

    class HoldingClass {
        @Published var username: String = ""
    }

    enum failureCondition: Error {
        case selfDestruct
    }

    private final class KVOAbleNSObject: NSObject {
        @objc dynamic var intValue: Int = 0
        @objc dynamic var boolValue: Bool = false
    }

    func testPublishedOnStruct() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingStruct()

        let cancellable = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testPublishedOnClassInstance() {
        let expectation = XCTestExpectation(description: "async sink test")
        let foo = HoldingClass()

        let cancellable = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testPublishedOnStructWithChange() {
        // NOTE(heckj) this test succeeded on beta 2, but fails on beta3 and beta4.
        // documented to Apple as FB6608729
        // beta2: ✅
        // beta3: ❌
        // beta4: ❌
        let expectation = XCTestExpectation(description: self.debugDescription)
        var foo = HoldingStruct()
        let q = DispatchQueue(label: self.debugDescription)

        let cancellable = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                if someString == "redfish" {
                    expectation.fulfill()
                }
        }
        q.async {
            print("Updating to redfish on background queue")
            foo.username = "redfish"
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testPublishedOnClassWithChange() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: self.debugDescription)

        let cancellable = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                if someString == "redfish" {
                    expectation.fulfill()
                }
        }
        q.async {
            print("Updating to redfish on background queue")
            foo.username = "redfish"
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testPublishedOnClassWithTwoSubscribers() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: self.debugDescription)
        var countOfHits = 0

        let _ = foo.$username
            .print("first subscriber")
            .sink { someString in
                print("first subscriber: value of username updated to: ", someString)
                if someString == "redfish" {
                    countOfHits += 1
                }

        }
        let _ = foo.$username
            .print("second subscriber")
            .sink { someString in
                print("second subscriber: value of username updated to: ", someString)
                if someString == "bluefish" {
                    countOfHits += 1
                    expectation.fulfill()
                }
        }

        q.async {
            print("Updating to redfish on background queue")
            foo.username = "redfish"
        }
        q.asyncAfter(deadline: .now() + 0.5, execute: {
            print("Updating to bluefish on background queue")
            foo.username = "bluefish"
        })
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(countOfHits, 2)
    }

    func testPublishedSinkWithError() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: self.debugDescription)

        let cancellable = foo.$username
            .print(self.debugDescription)
            .tryMap({ myValue -> String in
                if (myValue == "boom") {
                    throw failureCondition.selfDestruct
                }
                return "mappedValue"
            })
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case .failure(let anError):
                    print("received error: ", anError)
                    break
                }
            }, receiveValue: { postmanResponse in
                XCTAssertNotNil(postmanResponse)
                print(".sink() data received \(postmanResponse)")
            })

        q.async {
            print("Updating to redfish on background queue")
            foo.username = "redfish"
        }
        q.asyncAfter(deadline: .now() + 0.5, execute: {
            print("Updating to boom on background queue")
            foo.username = "boom"
        })
        // since the "boom" value will cause the error to be thrown with the
        // tryMap in the pipeline attached to the sink, the sink will send a
        // cancel message (visible in the test output for this test due to
        // the .print() operator), and no further changes will be published.
        q.asyncAfter(deadline: .now() + 1, execute: {
            print("Updating to bluefish on background queue")
            foo.username = "bluefish"
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(foo.username, "bluefish")
        XCTAssertNotNil(cancellable)
    }

    func testKVOPublisher() {
        let expectation = XCTestExpectation(description: self.debugDescription)
        let foo = KVOAbleNSObject()
        let q = DispatchQueue(label: self.debugDescription)

        let cancellable = foo.publisher(for: \.intValue)
            .print()
            .sink { someValue in
                print("value of intValue updated to: >>\(someValue)<<")
            }

        q.asyncAfter(deadline: .now() + 0.5, execute: {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 5
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

}
