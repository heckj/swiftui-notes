//
//  SwiftUI_CombineTests.swift
//  SwiftUI-NotesTests
//
//  Created by Joseph Heck on 6/13/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class SwiftUI_CombineTests: XCTestCase {
    func testVerifySignature() {
        let x = PassthroughSubject<String, Never>()
            .flatMap { _ in
                Future<String, Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    "\(result) foo"
                }
            }.eraseToAnyPublisher()

        let y = PassthroughSubject<String, Never>()
            .flatMap { _ in
                Future<String, Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    "\(result) foo"
                }
            }

        print("composed type")
        print(type(of: x.self))
        print("erased type")
        print(type(of: y.self))
    }

    func testSimplePipeline() {
        _ = Just(5)
            .map { value -> String in
                switch value {
                case _ where value < 1:
                    return "none"
                case _ where value == 1:
                    return "one"
                case _ where value == 2:
                    return "couple"
                case _ where value == 3:
                    return "few"
                case _ where value > 8:
                    return "many"
                default:
                    return "some"
                }
            }
            .sink { receivedValue in
                print("The end result was \(receivedValue)")
            }
    }

    func testSimpleSequencePublisher() {
        let originalListOfString = ["foo", "bar", "baz"]

        // this publishes the stream combo: <String>,<Never>
        let foo = Publishers.Sequence<[String], Never>(sequence: originalListOfString)

        // this may be a lot more sensible to create with a PropertyWrapper of some form...
        // there's a hint (that I haven't clued into) at the bottom of Combine of a function on Sequence called
        // publisher() that returns a publisher<Self, Never>

        let printingSubscriber = foo.sink { data in
            print(data)
        }

        _ = foo
            .collect(3)
            .sink { (listOfStrings: [String]) in
                XCTAssertEqual(listOfStrings, originalListOfString)
            }

        XCTAssertNotNil(printingSubscriber)
    }

    func testAnyFuture_CreationAndUse() {
        // A generic Future that always returns <Any>"A result"
        let goodPlace = Future<Any, Never> { promise in
            promise(.success("A result"))
        }

        let goodSinkHolder = goodPlace.sink(receiveValue: { receivedThing in
            // receiveValue here is typed as "<Any>"
            XCTAssertNotNil(receivedThing)
            print(receivedThing)
        })

        // just to hide the Xcode "unused" warnings really...
        XCTAssertNotNil(goodSinkHolder)
        XCTAssertNotNil(goodPlace)
    }

    func testStringFuture_CreationAndUse() {
        // A generic Future that always returns <Any>"A result"
        let goodPlace = Future<String, Never> { promise in
            promise(.success("A result"))
        }

        let goodSinkHolder = goodPlace.sink(receiveValue: { receivedThing in
            // receivedThing here is typed as String
            XCTAssertNotNil(receivedThing)
            // which makes it a lot easier to assert against
            XCTAssertEqual(receivedThing, "A result")
        })

        // just to hide the Xcode "unused" warnings really...
        XCTAssertNotNil(goodSinkHolder)
        XCTAssertNotNil(goodPlace)
    }

    /* - using this to explore - not functional or useful yet
     func testPublisherFor() {

         let x: String = "whassup"

         // as good a place to start as any...
         let publisher = PassthroughSubject<String?, Never>()
             // Publishers.ValueForKey
         .publisher(for: \.foo) // <- This is for getting a keypath to a property - not sure if it's passed down from the publisher, or if this is meant to send to a publisher keypath that the code scope has access to... (a variant on sink or assign)
     }
      */

    func testAnyFuture_FailingAFuture() {
        enum SampleError: Error {
            case exampleError
            case aDifferentError
        }

        // A generic Future that always returns a Failure
        let badPlace = Future<String, SampleError> { promise in
            // promise is Result<Any, Error> and this is expect to return Void
            // you generally call promise with .success() or .failure() enclosing relevant information (or results)
            promise(.failure(SampleError.exampleError))
        }

        // NOTE(heckj) I'm not entirely clear on how you can/should check failure path of a result chain
        // .sink() is a good place to drop in assertions for determining what happened in the success path,
        // but never gets called when a Future publisher sends a failure result.

        // IDEA: using .assertNoFailure()
        //   this causes a fatalException and invoke the debugger if you try this path

        // badPlace
        //    .assertNoFailure()

        // IDEA: Can we use "mapError" and slip in assert to validate the failure propagating through the chain?

        //   unfortunately, no - sticking an assert as the only thing in that closure will return it, which causes
        // the compiler to complain about changing the error type to the Error type that XCTAssert... methods
        // use to validate the test case.

        //   and using an assert in the sequence either never gets executed or doesn't end up propagating the error
        // up to the test runner.

        /*
         let _ = badPlace
             .mapError({ someError -> SampleError in // -> SampleError is because the compiler can't infer the type...
                 XCTAssertNil(someError) // by itself this errors with: Cannot convert value of type '()' to closure result type '_'
                 // XCTAssertEqual(SampleError.exampleError, someError)
                 // This doesn't work, compiler error: "Protocol type 'Error' cannot conform to 'Equatable' because only concrete types can conform to protocols"
                 return SampleError.aDifferentError
             })
          */

        // one way that *does* appear to work is to explicitly catch the error and using .catch() to
        // convert it into a result value, and then verify that result value gets called.
        _ = badPlace
            .catch { _ in
                // expected to return a publisher of SOME form...
                // .catch() is used to keep the whole stream alive and connected

                // XCTAssertNotNil(someError)
                // trying to assert anything in the catch results in the compiler erroring:
                // Cannot invoke 'sink' with an argument list of type '(receiveValue: @escaping (Any) -> Void)'

                // while this is catching an error, I'm not entirely clear on if you can validate
                // the kind and any details of the specifics of the instance of error - that is, which
                // error happened...
                Just("yo")
            }
            .sink(receiveValue: { placeholder in
                XCTAssertEqual(placeholder, "yo")
            })
    }

    // IDEA: It might make more sense to use Subject to check/test values being processed in Combine
    // rather than dropping them into .sink() which triggers the invocation of everything, and in which failures
    // propagate upward to see a failure.
}
