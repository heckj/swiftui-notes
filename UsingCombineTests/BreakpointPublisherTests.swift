//
//  BreakpointPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/27/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class BreakpointPublisherTests: XCTestCase {

    enum testFailureCondition: Error {
        case invalidServerResponse
    }

    func testBreakpointOnError() {

        let publisher = PassthroughSubject<String?, Error>()

        // this sets up the chain of whatever it's going to do
        let cancellable = publisher
            .tryMap { stringValue in
                throw testFailureCondition.invalidServerResponse
            }
            .breakpointOnError()
            .sink(
                // sink captures and terminates the pipeline of operators
                receiveCompletion: { completion in
                    print("sink captured the completion of \(String(describing: completion))")
                },
                receiveValue: { aValue in
                    print("sink captured the result of \(String(describing: aValue))")
                }
            )

        publisher.send("DATA IN")
        publisher.send(completion: .finished)
        XCTAssertNotNil(cancellable)
    }

        func testBreakpointOnSubscription() {

            let publisher = PassthroughSubject<String?, Error>()

            // this sets up the chain of whatever it's going to do
            let cancellable = publisher
                .breakpoint(receiveSubscription: { subscription in
                    return true // triggers breakpoint
                }, receiveOutput: { value in
                    return false
                }, receiveCompletion: { completion in
                    return false
                })
                .sink(
                    receiveCompletion: { completion in
                        print("sink captured the completion of \(String(describing: completion))")
                    },
                    receiveValue: { aValue in
                        print("sink captured the result of \(String(describing: aValue))")
                    }
                )

            publisher.send("DATA IN")
            publisher.send(completion: .finished)
            XCTAssertNotNil(cancellable)
        }

        func testBreakpointOnData() {

            let publisher = PassthroughSubject<String?, Error>()
            let cancellable = publisher
                .breakpoint(receiveSubscription: { subscription in
                    return false
                }, receiveOutput: { value in
                    return true // triggers breakpoint
                }, receiveCompletion: { completion in
                    return false
                })
                .map {
                    $0 // does nothing, but can be convenient to hang a debugger breakpoint on to see the data
                }
                .sink(
                    // sink captures and terminates the pipeline of operators
                    receiveCompletion: { completion in
                        print("sink captured the completion of \(String(describing: completion))")
                    },
                    receiveValue: { aValue in
                        print("sink captured the result of \(String(describing: aValue))")
                    }
                )

            publisher.send("DATA IN")
            publisher.send(completion: .finished)
            XCTAssertNotNil(cancellable)
        }
}
