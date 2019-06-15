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

        let originalListOfString = ["foo", "bar", "baz"]

        // this publishes the stream combo: <String>,<Never>
        let foo = Publishers.Sequence<Array<String>, Never>(sequence: originalListOfString)

        // this may be a lot more sensible to create with a PropertyWrapper of some form...
        // there's a hint (that I haven't clued into) at the bottom of Combine of a function on Sequence called
        // publisher() that returns a publisher<Self, Never>


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
        // A generic Future that always returns <Any>"A result"
        let goodPlace = Publishers.Future<Any, Error> { promise in
            promise(.success("A result"))
        }

        enum sampleError: Error {
            case exampleError
        }

        // A generic Future that always returns a Failure
        let badPlace = Publishers.Future<Any, Error> { promise in
            // promise is Result<Any, Error> and this is expect to return Void
            // you generally call promise with .success() or .failure() enclosing relevant information (or results)
            promise(.failure(sampleError.exampleError))
        }

        let goodSinkHolder = goodPlace.sink(receiveValue: { receivedThing in
            XCTAssertNotNil(receivedThing)
            print("Got something from this here Future.... : ")
            print(receivedThing)
        })

        let badSinkHolder = badPlace
            //.assertNoFailure() // kind of expecting this to blow up... and it does
//            .mapError({ someError in
//                XCTAssertNotNil(someError) // this errors with: Cannot convert value of type '()' to closure result type '_'
//            })
            .catch({ someError in
                // XCTAssertNotNil(someError)
                // trying to assert anything in the catch results in the compiler erroring:
                // Cannot invoke 'sink' with an argument list of type '(receiveValue: @escaping (Any) -> Void)'

                // expected to return a publisher of SOME form...
                // .catch() is used to keep the whole stream alive and connected
                return Publishers.Just("yo")
            })
            .sink(receiveValue: { placeholder in
                print("We got a ", placeholder)
                // this will never get invoked?
        })

        // just to hide the Xcode "unused" warnings really...
        XCTAssertNotNil(goodSinkHolder)
        XCTAssertNotNil(badSinkHolder)
        XCTAssertNotNil(goodPlace)
        XCTAssertNotNil(badPlace)
    }
}
