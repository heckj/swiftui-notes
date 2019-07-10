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

    func testPublishedOnStruct() {
        let expectation = XCTestExpectation(description: "async sink test")
        let foo = HoldingStruct()

        let _ = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }

    func testPublishedOnClassInstance() {
        let expectation = XCTestExpectation(description: "async sink test")
        let foo = HoldingClass()

        let _ = foo.$username
            .sink { someString in
                print("value of username updated to: >>\(someString)<<")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }

    func testPublishedOnStructWithChange() {
        let expectation = XCTestExpectation(description: "async sink test")
        var foo = HoldingStruct()
        let q = DispatchQueue(label: self.debugDescription)

        let _ = foo.$username
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
    }

    func testPublishedOnClassWithChange() {
        let expectation = XCTestExpectation(description: "async sink test")
        let foo = HoldingClass()
        let q = DispatchQueue(label: self.debugDescription)

        let _ = foo.$username
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
    }

    func testPublishedOnClassWithTwoSubscribers() {
        let expectation = XCTestExpectation(description: "async sink test")
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
}
