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

    func testSimplePipeline() {

        let _ = Publishers.Just(5)
            .map { value in
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
        let foo = Publishers.Sequence<Array<String>, Never>(sequence: originalListOfString)

        // this may be a lot more sensible to create with a PropertyWrapper of some form...
        // there's a hint (that I haven't clued into) at the bottom of Combine of a function on Sequence called
        // publisher() that returns a publisher<Self, Never>


        let printingSubscriber = foo.sink { data in
            print(data)
        }

        let _ = foo
            .collect(3)
            .sink { (listOfStrings: [String]) in
                XCTAssertEqual(listOfStrings, originalListOfString)
            }

        XCTAssertNotNil(printingSubscriber)
    }

    func testAnyFuture_CreationAndUse() {
        // A generic Future that always returns <Any>"A result"
        let goodPlace = Publishers.Future<Any, Error> { promise in
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
        let goodPlace = Publishers.Future<String, Error> { promise in
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

    func testSendingWithSubject() {
        // borrowing from CareKit test case at
        // https://github.com/carekit-apple/CareKit/blob/master/CareKit/CareKitTests/TestSynchronizedViewController.swift

        let publisher = PassthroughSubject<String?, Never>()
        // publisher is something where we control when data gets sent, which we do later
        // with the publisher.send() function

        // this sets up the chain of whatever it's going to do
        let _ = publisher
            .handleEvents(receiveSubscription: { stringValue in
                print("receiveSubscription event called with \(String(describing: stringValue))")
                // this happened second:
                // receiveSubscription event called with PassthroughSubject
            }, receiveOutput: { stringValue in
                // third:
                // handle events gives us an interesting window into all the flow mechanisms that
                // can happen during the Publish/Subscribe conversation, including capturing when
                // we receive completions, values, etc
                print("receiveOutput was invoked with \(String(describing: stringValue))")
            }, receiveCompletion: { stringValue in
                // no completions were sent in this test
                print("receiveCompletion event called with \(String(describing: stringValue))")
            }, receiveCancel: {
                // no cancellations sent in this test
                print("receiveCancel event invoked")
            }, receiveRequest: { stringValue in
                print("receiveRequest event called with \(String(describing: stringValue))")
                // this happened first:
                // receiveRequest event called with unlimited
            })
        .sink(receiveValue: { receivedValue in
            // sink captures and terminates the pipeline of operators
            print("sink captured the result of \(String(describing: receivedValue))")
        })

        // this is where we trigger the data to cascade through
        // The whole process is driving by the subscribers, and handleEvents() and sink()
        // above have set up a subscriber asking for "infinite data" - so the subscription
        // part of this thing has already happened. Which means that we can now control
        // what we send and when we send it using publisher.send() and test the results
        // of whatever we set up in the pipeline.

        // CareKit did that by asserting an initial value of something, then sending the data
        // and validating that the value had changed. (Bindable property, etc)
        publisher.send("DATA IN")
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
        enum sampleError: Error {
            case exampleError
            case aDifferentError
        }

        // A generic Future that always returns a Failure
        let badPlace = Publishers.Future<String, sampleError> { promise in
            // promise is Result<Any, Error> and this is expect to return Void
            // you generally call promise with .success() or .failure() enclosing relevant information (or results)
            promise(.failure(sampleError.exampleError))
        }

        // NOTE(heckj) I'm not entirely clear on how you can/should check failure path of a result chain
        // .sink() is a good place to drop in assertions for determining what happened in the success path,
        // but never gets called when a Future publisher sends a failure result.

        // IDEA: using .assertNoFailure()
        //   this causes a fatalException and invoke the debugger if you try this path

        // badPlace
        //    .assertNoFailure()


        // IDEA: Can we use "mapError" and slip in assert to validate the failure propogating through the chain?

        //   unfortunately, no - sticking an assert as the only thing in that closure will return it, which causes
        // the compiler to complain about changing the error type to the Error type that XCTAssert... methods
        // use to validate the test case.

        //   and using an assert in the sequence either never gets executed or doesn't end up propogating the error
        // up to the test runner.

        /*
        let _ = badPlace
            .mapError({ someError -> sampleError in // -> sampleError is because the compiler can't infer the type...
                XCTAssertNil(someError) // by itself this errors with: Cannot convert value of type '()' to closure result type '_'
                // XCTAssertEqual(sampleError.exampleError, someError)
                // This doesn't work, compiler error: "Protocol type 'Error' cannot conform to 'Equatable' because only concrete types can conform to protocols"
                return sampleError.aDifferentError
            })
         */

        // one way that *does* appear to work is to explicitly catch the error and using .catch() to
        // convert it into a result value, and then verify that result value gets called.
        let _ = badPlace
            .catch({ someError in
                // expected to return a publisher of SOME form...
                // .catch() is used to keep the whole stream alive and connected

                // XCTAssertNotNil(someError)
                // trying to assert anything in the catch results in the compiler erroring:
                // Cannot invoke 'sink' with an argument list of type '(receiveValue: @escaping (Any) -> Void)'

                // while this is catching an error, I'm not entirely clear on if you can validate
                // the kind and any details of the specifics of the instance of error - that is, which
                // error happened...
                return Publishers.Just("yo")
            })
            .sink(receiveValue: { placeholder in
                XCTAssertEqual(placeholder, "yo")
            })
    }

    // IDEA: It might make more sense to use Subject to check/test values being processed in Combine
    // rather than dropping them into .sink() which triggers the invocation of everything, and in which failures
    // propogate upward to see a failure.
}
