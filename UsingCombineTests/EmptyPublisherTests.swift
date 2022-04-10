//
//  EmptyPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class EmptyPublisherTests: XCTestCase {
    func testEmptyPublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let cancellable = Empty<String, Never>()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail("No failure should be received from empty")
                }
            }, receiveValue: { postmanResponse in
                XCTFail("No vaue should be received from empty")
                print(".sink() data received \(postmanResponse)")
            })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }
}
