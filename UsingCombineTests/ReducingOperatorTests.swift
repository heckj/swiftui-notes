//
//  ReducingOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/17/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class ReducingOperatorTests: XCTestCase {
    enum TestExampleError: Error {
        case nilValue
    }

    func testReduce() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        let cancellable = passSubj
            .reduce("") { prevVal, newValueFromPublisher -> String in
                prevVal + newValueFromPublisher
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail()
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

        var collectedResult: String?
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let cancellable = passSubj
            .reduce("") { prevVal, newValueFromPublisher -> String in
                prevVal + newValueFromPublisher
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
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

    func testTryReduce() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var endResult: String?

        let cancellable = passSubj
            .tryReduce("") { prevVal, newValueFromPublisher -> String in
                guard let upstreamValue = newValueFromPublisher else {
                    throw TestExampleError.nilValue
                }
                return prevVal + upstreamValue
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                endResult = responseValue
            })

        passSubj.send("hello")
        XCTAssertNil(endResult)
        passSubj.send(" ")
        XCTAssertNil(endResult)
        passSubj.send("world")
        XCTAssertNil(endResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(endResult, "hello world")

        XCTAssertNotNil(cancellable)
    }

    func testTryReduceWithThrownError() {
        let passSubj = PassthroughSubject<String?, Never>()
        // no initial value is propagated from a PassthroughSubject

        var endResult: String?
        var errorReceived = false

        let cancellable = passSubj
            .tryReduce("") { prevVal, newValueFromPublisher -> String in
                guard let upstreamValue = newValueFromPublisher else {
                    throw TestExampleError.nilValue
                }
                return prevVal + upstreamValue
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    errorReceived = true
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                endResult = responseValue
            })

        passSubj.send("hello")
        XCTAssertNil(endResult)
        XCTAssertFalse(errorReceived)
        passSubj.send(nil)
        XCTAssertTrue(errorReceived)
        XCTAssertNil(endResult)

        XCTAssertNotNil(cancellable)
    }

    func testCollect() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        let cancellable = passSubj
            .collect()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                XCTAssertEqual(responseValue, [1, 2])
            })

        passSubj.send(1)
        passSubj.send(2)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testCollectWithError() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        let cancellable = passSubj
            .collect()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                XCTFail() // no values will be received when an error is triggered
            })

        passSubj.send(1)
        passSubj.send(2)
        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.nilValue))
        XCTAssertNotNil(cancellable)
    }

    func testCollectWithCountUnder() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: [Int] = []

        let cancellable = passSubj
            .collect(3)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        passSubj.send(1)
        XCTAssertEqual(latestReceivedResult.count, 0)
        passSubj.send(2)
        XCTAssertEqual(latestReceivedResult.count, 0)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult.count, 2)
        XCTAssertEqual(latestReceivedResult, [1, 2])
        XCTAssertNotNil(cancellable)
    }

    func testCollectWithCountOver() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: [Int] = []

        let cancellable = passSubj
            .collect(3)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        passSubj.send(1)
        XCTAssertEqual(latestReceivedResult.count, 0)
        passSubj.send(2)
        XCTAssertEqual(latestReceivedResult.count, 0)
        passSubj.send(3)
        XCTAssertEqual(latestReceivedResult.count, 3)
        XCTAssertEqual(latestReceivedResult, [1, 2, 3])
        passSubj.send(4)
        XCTAssertEqual(latestReceivedResult, [1, 2, 3])
        passSubj.send(5)
        XCTAssertEqual(latestReceivedResult, [1, 2, 3])
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult, [4, 5])
        XCTAssertNotNil(cancellable)
    }

    func testCollectByTime() {
        let expectation = XCTestExpectation(description: debugDescription)
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: [Int] = []
        let q = DispatchQueue(label: debugDescription)

        let cancellable = passSubj
            // .collect(Publishers.TimeGroupingStrategy<DispatchQueue>.byTime(q, 1.0))
            // ^^ full type specification
            .collect(.byTime(q, 1.0))
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        q.asyncAfter(deadline: .now() + 0.1) {
            passSubj.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            passSubj.send(2)
        }
        q.asyncAfter(deadline: .now() + 0.3) {
            passSubj.send(3)
        }
        q.asyncAfter(deadline: .now() + 0.4) {
            passSubj.send(4)
        }

        q.asyncAfter(deadline: .now() + 1.01) {
            XCTAssertEqual(latestReceivedResult, [1, 2, 3, 4])
        }

        q.asyncAfter(deadline: .now() + 1.3) {
            passSubj.send(5)
        }
        q.asyncAfter(deadline: .now() + 1.4) {
            passSubj.send(6)
        }

        q.asyncAfter(deadline: .now() + 3) {
            passSubj.send(completion: Subscribers.Completion.finished)
        }

        q.asyncAfter(deadline: .now() + 3.01) {
            XCTAssertEqual(latestReceivedResult, [5, 6])
            expectation.fulfill()
        }

        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
    }

    func testCollectByTimeOrCount() {
        let expectation = XCTestExpectation(description: debugDescription)
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: [Int] = []
        let q = DispatchQueue(label: debugDescription)

        let cancellable = passSubj
            .collect(.byTimeOrCount(q, 1.0, 3))
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        q.asyncAfter(deadline: .now() + 0.1) {
            passSubj.send(1)
        }
        q.asyncAfter(deadline: .now() + 0.2) {
            passSubj.send(2)
        }
        q.asyncAfter(deadline: .now() + 0.3) {
            passSubj.send(3)
        }

        q.asyncAfter(deadline: .now() + 0.35) {
            XCTAssertEqual(latestReceivedResult, [1, 2, 3])
        }

        q.asyncAfter(deadline: .now() + 0.4) {
            passSubj.send(4)
        }
        q.asyncAfter(deadline: .now() + 0.5) {
            passSubj.send(5)
        }

        q.asyncAfter(deadline: .now() + 1.05) {
            XCTAssertEqual(latestReceivedResult, [4, 5])
        }

        q.asyncAfter(deadline: .now() + 1.3) {
            passSubj.send(6)
        }
        q.asyncAfter(deadline: .now() + 1.4) {
            passSubj.send(7)
        }

        q.asyncAfter(deadline: .now() + 3) {
            passSubj.send(completion: Subscribers.Completion.finished)
        }

        q.asyncAfter(deadline: .now() + 3.05) {
            XCTAssertEqual(latestReceivedResult, [6, 7])
            expectation.fulfill()
        }

        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
    }

    func testIgnoreOutputSuccess() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var finishReceived = false
        var failureReceived = false
        var dataCallbackReceived = false

        let cancellable = passSubj
            .ignoreOutput()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    finishReceived = true
                case let .failure(anError):
                    print("received error: ", anError)
                    failureReceived = true
                }
            }, receiveValue: { _ in
                print(".sink() data received")
                dataCallbackReceived = true
            })

        passSubj.send(1)
        XCTAssertFalse(finishReceived)
        XCTAssertFalse(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        passSubj.send(2)
        XCTAssertFalse(finishReceived)
        XCTAssertFalse(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertTrue(finishReceived)
        XCTAssertFalse(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        XCTAssertNotNil(cancellable)
    }

    func testIgnoreOutputFailure() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var finishReceived = false
        var failureReceived = false
        var dataCallbackReceived = false

        let cancellable = passSubj
            .ignoreOutput()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    finishReceived = true
                case let .failure(anError):
                    print("received error: ", anError)
                    failureReceived = true
                }
            }, receiveValue: { _ in
                print(".sink() data received")
                dataCallbackReceived = true
            })

        passSubj.send(1)
        XCTAssertFalse(finishReceived)
        XCTAssertFalse(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        passSubj.send(2)
        XCTAssertFalse(finishReceived)
        XCTAssertFalse(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.nilValue))
        XCTAssertFalse(finishReceived)
        XCTAssertTrue(failureReceived)
        XCTAssertFalse(dataCallbackReceived)

        XCTAssertNotNil(cancellable)
    }
}
