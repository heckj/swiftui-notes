//
//  RetryPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class RetryPublisherTests: XCTestCase {

    enum testFailureCondition: Error {
        case invalidServerResponse
    }

    func testRetryOperatorWithPassthroughSubject() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Error>()

        let cancellable = simpleControlledPublisher
            .print(self.debugDescription)
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
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))

        // with a completion, this prints two results and ends
        //simpleControlledPublisher.send(completion: .finished)

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
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))
        XCTAssertNotNil(cancellable)
        // with a completion, this prints two results and ends
        //simpleControlledPublisher.send(completion: .finished)

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

        let cancellable = Fail(outputType: String.self, failure: testFailureCondition.invalidServerResponse)
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
        //        ** .sink() received the completion: failure(SwiftUI_NotesTests.CombinePatternTests.testFailureCondition.invalidServerResponse)
        //        (2)>: receive subscription: (Retry)
        //        (2)>: request unlimited

    }

}
