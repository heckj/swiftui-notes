//
//  ReducingOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/17/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class ReducingOperatorTests: XCTestCase {

    func testReduce() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propogated from a PassthroughSubject

        let cancellable = passSubj
        .reduce("", { prevVal, newValueFromPublisher -> String in
            return prevVal+newValueFromPublisher
        })
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                XCTFail()
                break
            }
        }, receiveValue: { responseValue in
            XCTAssertEqual(responseValue, "hello world")
            print(".sink() data received \(responseValue)")
        })

        passSubj.send("hello")
        passSubj.send(" ")
        passSubj.send("world")
        passSubj.send(completion: Subscribers.Completion.finished)

        XCTAssertNotNil(cancellable)
    }

    func testReduceWithError() {

        enum TestExampleError: Error {
            case example
        }

        var collectedResult : String?
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propogated from a PassthroughSubject

        let cancellable = passSubj
            .reduce("", { prevVal, newValueFromPublisher -> String in
            return prevVal+newValueFromPublisher
        })
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            switch completion {
            case .finished:
                XCTFail()
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
            }
        }, receiveValue: { responseValue in
            print(".sink() data received \(responseValue)")
            collectedResult = responseValue
            XCTFail()
        })

        passSubj.send("hello")
        passSubj.send(" ")
        passSubj.send("world")
        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.example))
        XCTAssertNil(collectedResult)
        XCTAssertNotNil(cancellable)
    }
}
