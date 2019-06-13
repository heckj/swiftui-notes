//
//  SwiftUI_CombineTests.swift
//  SwiftUI-NotesTests
//
//  Created by Joseph Heck on 6/13/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class SwiftUI_CombineTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleSequencePublisher() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let originalListOfString = ["foo", "bar", "baz"]
        let foo = Publishers.Sequence<Array<String>, Never>(sequence: originalListOfString)
        // this publishes the stream combo: <String>,<Never>

        let printingSubscriber = foo.sink { data in
            print(data)
        }

        let countingCollector = foo
            .collect(3)
            .sink { (listOfStrings: [String]) in
                XCTAssertEqual(listOfStrings, originalListOfString)
            }

        XCTAssertNotNil(printingSubscriber)
        XCTAssertNotNil(countingCollector)
        print("fini")
    }

    func testFutureMaking() {
//        let x = Future { promise in
//            promise(.success("a result"))
//        }
        // THIS should be creating a Result<String, Error>, but I don't think the initial release
        // includes the Future convenience - not finding it in the documentation either... only the WWDC
        // presentation data
    }
}
