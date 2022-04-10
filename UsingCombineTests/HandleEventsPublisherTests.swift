//
//  HandleEventsPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class HandleEventsPublisherTests: XCTestCase {
    func testHandleEvents() {
        let publisher = PassthroughSubject<String?, Never>()

        // this sets up the chain of whatever it's going to do
        let cancellable = publisher
            .handleEvents(receiveSubscription: { aValue in
                print("receiveSubscription event called with \(String(describing: aValue))")
                // this happened second:
                // receiveSubscription event called with PassthroughSubject
                XCTAssertNotNil(aValue) // type returned is a Subscription
            }, receiveOutput: { aValue in
                // third:
                // handle events gives us an interesting window into all the flow mechanisms that
                // can happen during the Publish/Subscribe conversation, including capturing when
                // we receive completions, values, etc
                print("receiveOutput was invoked with \(String(describing: aValue))")
                XCTAssertEqual(aValue, "DATA IN")
            }, receiveCompletion: { aValue in
                // completion .finished were sent in this test
                print("receiveCompletion event called with \(String(describing: aValue))")
            }, receiveCancel: {
                // no cancellations sent in this test
                print("receiveCancel event invoked")
                XCTFail("cancel should not be received in this test")
            }, receiveRequest: { aValue in
                print("receiveRequest event called with \(String(describing: aValue))")
                // this happened first:
                // receiveRequest event called with unlimited
                XCTAssertEqual(aValue, Subscribers.Demand.unlimited)
            })
            .sink(receiveValue: { aValue in
                // sink captures and terminates the pipeline of operators
                print("sink captured the result of \(String(describing: aValue))")
            })

        publisher.send("DATA IN")
        publisher.send(completion: .finished)
        XCTAssertNotNil(cancellable)
    }
}
