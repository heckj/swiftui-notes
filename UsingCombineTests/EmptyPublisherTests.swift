//
//  EmptyPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class EmptyPublisherTests: XCTestCase {

    func testEmptyPublisher() {
        let expectation = XCTestExpectation(description: self.debugDescription)

        let _ = Publishers.Empty<String, Never>()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    expectation.fulfill()
                    break
                case .failure(let anError):
                    print("received error: ", anError)
                    XCTFail("No failure should be received from empty")
                    break
                }
            }, receiveValue: { postmanResponse in
                XCTFail("No vaue should be received from empty")
                print(".sink() data received \(postmanResponse)")
            })

        wait(for: [expectation], timeout: 5.0)
    }

}
