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

    enum TestFailureCondition: Error {
        case invalidServerResponse
    }

    /* NOTE(heckj):
     - these tests have all been prefixed with SKIP_ so they won't be run automatically with a whole
       project validation. They explicitly drop breakpoints into the debugger, which is great when
       you're actively debugging, but a complete PITA when you're trying to see a whole test sequence run.
     */
    func SKIP_testBreakpointOnError() {

        let publisher = PassthroughSubject<String?, Error>()

        // this sets up the chain of whatever it's going to do
        let cancellable = publisher
            .tryMap { stringValue in
                throw TestFailureCondition.invalidServerResponse
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

    func SKIP_testBreakpointOnSubscription() {

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

    func SKIP_testBreakpointOnData() {

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
