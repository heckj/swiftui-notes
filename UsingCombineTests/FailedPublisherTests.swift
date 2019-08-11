//
//  FailedPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class FailedPublisherTests: XCTestCase {

    enum testFailureCondition: Error {
        case exampleFailure
    }

    func testFailPublisher() {
        let expectation = XCTestExpectation(description: self.debugDescription)

        let cancellable = Fail<String, Error>(error: testFailureCondition.exampleFailure)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("No failure should be received from empty")
                    break
                case .failure(let anError):
                    print("received error: ", anError)
                    break
                }
                expectation.fulfill()
            }, receiveValue: { postmanResponse in
                XCTFail("No vaue should be received from empty")
                print(".sink() data received \(postmanResponse)")
            })

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(cancellable)
    }

}
