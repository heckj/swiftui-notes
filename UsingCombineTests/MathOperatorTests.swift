//
//  MathOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/17/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class MathOperatorTests: XCTestCase {
    func testMax() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: Int?

        let cancellable = passSubj
            .max()
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
        XCTAssertNil(latestReceivedResult)
        passSubj.send(2)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult, 2)
        XCTAssertNotNil(cancellable)
    }

    struct ExampleStruct {
        var property1: Int
        var property2: Int?
    }

    enum TestExampleError: Error {
        case nilValue
    }

    func testMaxWithClosure() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?

        let cancellable = passSubj
            .max { struct1, struct2 -> Bool in
                struct1.property1 < struct2.property1
                // returning boolean true to order struct2 greater than struct1
                // the underlying method parameter for this closure hints to it:
                // `areInIncreasingOrder`
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
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(ExampleStruct(property1: 3, property2: 4))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult!.property1, 3)
        XCTAssertEqual(latestReceivedResult!.property2, 4)
        XCTAssertNotNil(cancellable)
    }

    func testTryMaxWithClosure() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?

        let cancellable = passSubj
            .tryMax { struct1, struct2 -> Bool in
                guard let concrete1 = struct1.property2, let concrete2 = struct2.property2 else {
                    throw TestExampleError.nilValue
                }
                return concrete1 < concrete2
                // returning boolean true to order struct2 greater than struct1
                // the underlying method parameter for this closure hints to it:
                // `areInIncreasingOrder`
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
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(ExampleStruct(property1: 3, property2: 4))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult!.property1, 3)
        XCTAssertEqual(latestReceivedResult!.property2, 4)
        XCTAssertNotNil(cancellable)
    }

    func testTryMaxWithClosureError() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?
        var failureReceived = false

        let cancellable = passSubj
            .tryMax { struct1, struct2 -> Bool in
                guard let concrete1 = struct1.property2, let concrete2 = struct2.property2 else {
                    throw TestExampleError.nilValue
                }
                return concrete1 < concrete2
                // returning boolean true to order struct2 greater than struct1
                // the underlying method parameter for this closure hints to it:
                // `areInIncreasingOrder`
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    failureReceived = true
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        XCTAssertFalse(failureReceived)
        passSubj.send(ExampleStruct(property1: 3, property2: nil))
        XCTAssertNil(latestReceivedResult)
        XCTAssertTrue(failureReceived)

        XCTAssertNotNil(cancellable)
    }

    func testMin() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: Int?

        let cancellable = passSubj
            .min()
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
        XCTAssertNil(latestReceivedResult)
        passSubj.send(2)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult, 1)
        XCTAssertNotNil(cancellable)
    }

    func testMinWithClosure() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?

        let cancellable = passSubj
            .min { struct1, struct2 -> Bool in
                struct1.property1 < struct2.property1
                // returning boolean true to order struct2 greater than struct1
                // the underlying method parameter for this closure hints to it:
                // `areInIncreasingOrder`
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
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(ExampleStruct(property1: 3, property2: 4))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult!.property1, 1)
        XCTAssertEqual(latestReceivedResult!.property2, 2)
        XCTAssertNotNil(cancellable)
    }

    func testTryMinWithClosure() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?

        let cancellable = passSubj
            .tryMin { struct1, struct2 -> Bool in
                guard let concrete1 = struct1.property2, let concrete2 = struct2.property2 else {
                    throw TestExampleError.nilValue
                }
                return concrete1 < concrete2
                // returning boolean true to order struct2 greater than struct1
                // the underlying method parameter for this closure hints to it:
                // `areInIncreasingOrder`
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
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(ExampleStruct(property1: 3, property2: 4))
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult!.property1, 1)
        XCTAssertEqual(latestReceivedResult!.property2, 2)
        XCTAssertNotNil(cancellable)
    }

    func testTryMinWithClosureError() {
        let passSubj = PassthroughSubject<ExampleStruct, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: ExampleStruct?
        var failureReceived = false

        let cancellable = passSubj
            .tryMin { struct1, struct2 -> Bool in
                guard let concrete1 = struct1.property2, let concrete2 = struct2.property2 else {
                    throw TestExampleError.nilValue
                }
                return concrete1 < concrete2
                // returning boolean true to order struct2 greater than struct1
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    failureReceived = true
                }
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedResult = responseValue
            })

        passSubj.send(ExampleStruct(property1: 1, property2: 2))
        XCTAssertNil(latestReceivedResult)
        XCTAssertFalse(failureReceived)
        passSubj.send(ExampleStruct(property1: 3, property2: nil))
        XCTAssertNil(latestReceivedResult)
        XCTAssertTrue(failureReceived)

        XCTAssertNotNil(cancellable)
    }

    func testCount() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: Int?

        let cancellable = passSubj
            .count()
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

        passSubj.send(9)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(8)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedResult, 2)
        XCTAssertNotNil(cancellable)
    }

    func testCountError() {
        let passSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var latestReceivedResult: Int?

        let cancellable = passSubj
            .count()
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

        passSubj.send(9)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(8)
        XCTAssertNil(latestReceivedResult)
        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.nilValue))
        XCTAssertNil(latestReceivedResult)

        XCTAssertNotNil(cancellable)
    }
}
