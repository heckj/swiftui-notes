//
//  RetryPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class RetryPublisherTests: XCTestCase {
    enum TestFailureCondition: Error {
        case invalidServerResponse
    }

    func testRetryOperatorWithPassthroughSubject() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Error>()

        let cancellable = simpleControlledPublisher
            .print(debugDescription)
            .retry(1)
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })

        let oneFish = "onefish"
        let twoFish = "twofish"
        let redFish = "redfish"
        let blueFish = "bluefish"

        simpleControlledPublisher.send(oneFish)
        simpleControlledPublisher.send(twoFish)

        // with an error response, this prints two results and hangs...
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))

        // with a completion, this prints two results and ends
        // simpleControlledPublisher.send(completion: .finished)

        simpleControlledPublisher.send(redFish)
        simpleControlledPublisher.send(blueFish)
        XCTAssertNotNil(cancellable)
    }

    func testRetryOperatorWithCurrentValueSubject() {
        // setup
        let simpleControlledPublisher = CurrentValueSubject<String, Error>("initial value")

        let cancellable = simpleControlledPublisher
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })

        let oneFish = "onefish"

        simpleControlledPublisher.send(oneFish)
        // with an error response, this prints two results and hangs...
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))
        XCTAssertNotNil(cancellable)
        // with a completion, this prints two results and ends
        // simpleControlledPublisher.send(completion: .finished)

        //        output:
        //        (1)>: receive subscription: (CurrentValueSubject)
        //        (2)>: receive subscription: (Retry)
        //        (2)>: request unlimited
        //        (1)>: request unlimited
        //        (1)>: receive value: (initial value)
        //        (2)>: receive value: (initial value)
        //        ** .sink() received initial value
        //        (1)>: receive value: (onefish)
        //        (2)>: receive value: (onefish)
        //        ** .sink() received onefish
        //        (1)>: receive finished
        //        (2)>: receive finished
        //        ** .sink() received the completion: finished
    }

    func testRetryWithOneShotJustPublisher() {
        // setup
        let cancellable = Just<String>("yo")
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })
        XCTAssertNotNil(cancellable)
        //        output:
        //        (1)>: receive subscription: (Just)
        //        (2)>: receive subscription: (Retry)
        //        (2)>: request unlimited
        //        (1)>: request unlimited
        //        (1)>: receive value: (yo)
        //        (2)>: receive value: (yo)
        //        ** .sink() received yo
        //        (1)>: receive finished
        //        (2)>: receive finished
        //        ** .sink() received the completion: finished
    }

    func testRetryWithOneShotFailPublisher() {
        // setup

        let cancellable = Fail(outputType: String.self, failure: TestFailureCondition.invalidServerResponse)
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })
        XCTAssertNotNil(cancellable)
        //        output:
        //        (1)>: receive subscription: (Empty)
        //        (1)>: receive error: (invalidServerResponse)
        //        (1)>: receive subscription: (Empty)
        //        (1)>: receive error: (invalidServerResponse)
        //        (1)>: receive subscription: (Empty)
        //        (1)>: receive error: (invalidServerResponse)
        //        (1)>: receive subscription: (Empty)
        //        (1)>: receive error: (invalidServerResponse)
        //        (2)>: receive error: (invalidServerResponse)
        //        ** .sink() received the completion: failure(SwiftUI_NotesTests.CombinePatternTests.TestFailureCondition.invalidServerResponse)
        //        (2)>: receive subscription: (Retry)
        //        (2)>: request unlimited
    }

    func testRetryDelayOnFailureOnly() {
        // setup
        let expectation = XCTestExpectation(description: debugDescription)
        var asyncAPICallCount = 0
        var futureClosureHandlerCount = 0

        let msTimeFormatter = DateFormatter()
        msTimeFormatter.dateFormat = "[HH:mm:ss.SSSS] "

        // example of a asynchronous function to be called from within a Future and its completion closure
        func instrumentedAsyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
            DispatchQueue.global(qos: .background).async {
                let delay = Int.random(in: 1 ... 3)
                print(msTimeFormatter.string(from: Date()) + " * starting async call (waiting \(delay) seconds before returning) ")
                asyncAPICallCount += 1
                sleep(UInt32(delay))
                print(msTimeFormatter.string(from: Date()) + " * completing async call ")
                if sabotage {
                    completionBlock(false, TestFailureCondition.invalidServerResponse)
                }
                completionBlock(true, nil)
            }
        }

        let upstreamPublisher = Deferred {
            Future<String, Error> { promise in
                futureClosureHandlerCount += 1
                // setting "sabotage: true" in the asyncAPICall tells the test code to return a
                // failure result, which will illustrate "retry" better.
                instrumentedAsyncAPICall(sabotage: true) { _, err in
                    // NOTE(heckj): the closure resolving the API call into a Promise result
                    // is called far more than 3 times - 5 in this example, although I don't know
                    // why that is. The underlying API call, and the closure within the future
                    // are each called 3 times - validated below in the assertions.
                    if let err = err {
                        return promise(.failure(err))
                    }
                    return promise(.success("allowed!"))
                }
            }
        }
        .eraseToAnyPublisher()

        // this test is an idea proposed by anachev (ref: https://github.com/heckj/swiftui-notes/issues/164)
        // on how to enable a "delay on error only". I have an example of using retry() with a random delay
        // elsewhere in the book (https://heckj.github.io/swiftui-notes/#patterns-retry), but it *always*
        // delays the call - which isn't an ideal solution.
        // This was his suggestion at an attempt to do better.

        let resultPublisher = upstreamPublisher.catch { _ -> AnyPublisher<String, Error> in
            print(msTimeFormatter.string(from: Date()) + "delaying on error for ~3 seconds ")
            return Publishers.Delay(upstream: upstreamPublisher,
                                    interval: 3,
                                    tolerance: 1,
                                    scheduler: DispatchQueue.global())
                // moving retry into this block reduces the number of duplicate requests
                // In effect, there's the original request, and the `retry(2)` here will operate
                // two additional retries on the otherwise one-shot publisher that is initiated with
                // the `Publishers.Delay()` just above. Just starting this publisher with delay makes
                // an additional request, so the total number of requests ends up being 4 (assuming all
                // fail). However, no delay is introduced in this sequence if the original request
                // is successful.
                .retry(2)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(asyncAPICallCount, 0)
        XCTAssertEqual(futureClosureHandlerCount, 0)

        let cancellable = resultPublisher.sink(receiveCompletion: { err in
            print(msTimeFormatter.string(from: Date()) + ".sink() received the completion: ", String(describing: err))

            // The surprise here is that the underlying asynchronous API call is made not 3 times, but 6 times.
            // From the output in the test, which includes timestamps down to the ms to make it easier to see WHEN
            // things are happening, the retry process ends up double-invoking the upstream publisher.
            XCTAssertEqual(asyncAPICallCount, 4)
            // the original request is 1, and then the Publishers.Delay() initiated request with a retry(2) are the others
            XCTAssertEqual(futureClosureHandlerCount, 4)
            // the original request is 1, and then the Publishers.Delay() initiated request with a retry(2) are the others
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
            XCTFail("no value should be returned")
        })

        wait(for: [expectation], timeout: 30.0)
        XCTAssertNotNil(cancellable)
    }
}
