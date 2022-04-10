//
//  PublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/10/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class PublisherTests: XCTestCase {
//    struct HoldingStruct {
//        @Published var username: String = ""
//    }

    /* NOTE(heckj):
     The above stanza (as of beta5) is now explicitly disallowed from the compiler, although it's
     not reported very clearly in Xcode. The compiler error from the above lines:

     <unknown>:0: error: 'wrappedValue' is unavailable: @Published is only available on properties of classes
     Combine.Published:5:16: note: 'wrappedValue' has been explicitly marked unavailable here
         public var wrappedValue: Value { get set }
                    ^

     Given that it's explicitly marked as unavailable, I'm presuming that the @Published annotation is
     only to be used with properties on reference types (classes), and commenting out the tests that had
     previously attempting to use it within a value type (struct).
     */

    class HoldingClass {
        @Published var username: String = ""
    }

    enum FailureCondition: Error {
        case selfDestruct
    }

    private final class KVOAbleNSObject: NSObject {
        @objc dynamic var intValue: Int = 0
        @objc dynamic var boolValue: Bool = false
    }

//    func testPublishedOnStruct() {
//        let expectation = XCTestExpectation(description: self.debugDescription)
//        let foo = HoldingStruct()
//
//        let cancellable = foo.$username
//            .sink { someString in
//                print("value of username updated to: >>\(someString)<<")
//                expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 5.0)
//        XCTAssertNotNil(cancellable)
//    }

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

//
//    func testPublishedOnStructWithChange() {
//        // NOTE(heckj) this test succeeded on beta 2, but fails on beta3 and beta4.
//        // documented to Apple as FB6608729
//        // beta2: ✅
//        // beta3: ❌
//        // beta4: ❌
//        // beta5: ❌ - compiler error
//        let expectation = XCTestExpectation(description: self.debugDescription)
//        var foo = HoldingStruct()
//        let q = DispatchQueue(label: self.debugDescription)
//
//        let cancellable = foo.$username
//            .sink { someString in
//                print("value of username updated to: >>\(someString)<<")
//                if someString == "redfish" {
//                    expectation.fulfill()
//                }
//        }
//        q.async {
//            print("Updating to redfish on background queue")
//            foo.username = "redfish"
//        }
//        wait(for: [expectation], timeout: 5.0)
//        XCTAssertNotNil(cancellable)
//    }

    func testPublishedOnClassWithChange() {
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: debugDescription)

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
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: debugDescription)
        var countOfHits = 0

        let cancellable1 = foo.$username
            .print("first subscriber")
            .sink { someString in
                print("first subscriber: value of username updated to: ", someString)
                if someString == "redfish" {
                    countOfHits += 1
                }
            }
        let cancellable2 = foo.$username
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
        q.asyncAfter(deadline: .now() + 0.5) {
            print("Updating to bluefish on background queue")
            foo.username = "bluefish"
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(countOfHits, 2)
        XCTAssertNotNil(cancellable1)
        XCTAssertNotNil(cancellable2)
    }

    func testPublishedSinkWithError() {
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = HoldingClass()
        let q = DispatchQueue(label: debugDescription)

        let cancellable = foo.$username
            .print(debugDescription)
            .tryMap { myValue -> String in
                if myValue == "boom" {
                    throw FailureCondition.selfDestruct
                }
                return "mappedValue"
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { postmanResponse in
                XCTAssertNotNil(postmanResponse)
                print(".sink() data received \(postmanResponse)")
            })

        q.async {
            print("Updating to redfish on background queue")
            foo.username = "redfish"
        }
        q.asyncAfter(deadline: .now() + 0.5) {
            print("Updating to boom on background queue")
            foo.username = "boom"
        }
        // since the "boom" value will cause the error to be thrown with the
        // tryMap in the pipeline attached to the sink, the sink will send a
        // cancel message (visible in the test output for this test due to
        // the .print() operator), and no further changes will be published.
        q.asyncAfter(deadline: .now() + 1) {
            print("Updating to bluefish on background queue")
            foo.username = "bluefish"
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(foo.username, "bluefish")
        XCTAssertNotNil(cancellable)
    }

    func testKVOPublisher() {
        let expectation = XCTestExpectation(description: debugDescription)
        let foo = KVOAbleNSObject()
        let q = DispatchQueue(label: debugDescription)

        let cancellable = foo.publisher(for: \.intValue)
            .print()
            .sink { someValue in
                print("value of intValue updated to: >>\(someValue)<<")
            }

        q.asyncAfter(deadline: .now() + 0.5) {
            print("Updating to foo.intValue on background queue")
            foo.intValue = 5
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }
}
