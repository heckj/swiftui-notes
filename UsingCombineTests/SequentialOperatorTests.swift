//
//  SequentialOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/21/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class SequentialOperatorTests: XCTestCase {
    enum TestExampleError: Error {
        case invalidValue
    }

    func testFirst() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .first()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["hello"])
        XCTAssertTrue(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["hello"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testFirstFinishedBeforeValue() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .first()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testFirstWhere() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .first { incomingobject -> Bool in
                incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["hello"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testFirstWhereFinishedBeforeValue() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .first { incomingobject -> Bool in
                incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryFirstWhere() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryFirst { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["hello"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryFirstWhereFinishedBeforeValue() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryFirst { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryFirstWhereWithError() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .tryFirst { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    errorReceived = true
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("boom")
        XCTAssertTrue(errorReceived)
        XCTAssertTrue(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        XCTAssertNotNil(cancellable)
    }

    func testLast() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .last()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("fini")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testLastWithFinishedBeforeValue() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .last()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testLastWhere() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .last { incomingobject -> Bool in
                incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("hello")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("world")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("fini")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testLastWhereFinished() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .last { incomingobject -> Bool in
                incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryLastWhere() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryLast { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("hello")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("world")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("fini")
        XCTAssertFalse(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryLastWhereFinished() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryLast { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryLastWhereWithError() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .tryLast { incomingobject -> Bool in
                if incomingobject == "boom" {
                    throw TestExampleError.invalidValue
                }
                return incomingobject.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    errorReceived = true
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("abc")
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)
        XCTAssertEqual(responses.count, 0)

        passSubj.send("boom")
        XCTAssertTrue(errorReceived)
        XCTAssertTrue(terminatedStream)
        XCTAssertEqual(responses.count, 0)

        XCTAssertNotNil(cancellable)
    }

    func testDropUntilOutput() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .drop(untilOutputFrom: triggerSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        triggerSubj.send(1)
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["world"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("fini")
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses, ["world", "fini"])
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses, ["world", "fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testDropUntilOutputTriggerFinishedBeforeValue() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .drop(untilOutputFrom: triggerSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        triggerSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testDropUntilOutputTriggerError() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var receivedError = false

        let cancellable = passSubj
            .drop(untilOutputFrom: triggerSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    receivedError = true
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(receivedError)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(receivedError)

        triggerSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(receivedError)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(receivedError)

        XCTAssertNotNil(cancellable)
    }

    func testDropUntilOutputFinished() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var receivedError = false

        let cancellable = passSubj
            .drop(untilOutputFrom: triggerSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    receivedError = true
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(receivedError)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(receivedError)

        XCTAssertNotNil(cancellable)
    }

    func testDropWhile() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .drop { upstreamValue -> Bool in
                upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("xyz")
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses, ["abc", "xyz"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("fini")
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "xyz", "fini"])
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "xyz", "fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testDropWhileEarlyTrigger() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .drop { upstreamValue -> Bool in
                upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        // less than 4 characters is the trigger in our test
        passSubj.send("abc")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses, ["abc", "hello"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "hello", "world"])
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "hello", "world"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testDropWhileFinished() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .drop { upstreamValue -> Bool in
                upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryDropWhile() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryDrop { upstreamValue -> Bool in
                if upstreamValue == "boom" {
                    throw TestExampleError.invalidValue
                }
                return upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("world")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send("abc")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("xyz")
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses, ["abc", "xyz"])
        XCTAssertFalse(terminatedStream)

        passSubj.send("fini")
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "xyz", "fini"])
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 3)
        XCTAssertEqual(responses, ["abc", "xyz", "fini"])
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testTryDropWhileEarlyTriggerAndError() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .tryDrop { upstreamValue -> Bool in
                if upstreamValue == "boom" {
                    throw TestExampleError.invalidValue
                }
                return upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("abc")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testTryDropWhileFinished() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
            .tryDrop { upstreamValue -> Bool in
                if upstreamValue == "boom" {
                    throw TestExampleError.invalidValue
                }
                return upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)

        XCTAssertNotNil(cancellable)
    }

    func testDropFirst() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .dropFirst()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("hello")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("abc")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["abc"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testDropFirstFinished() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .dropFirst()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 0)
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testDropFirstCount() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
            .dropFirst(3)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("first")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("second")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("third")
        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send("fourth")
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["fourth"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses, ["fourth"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testConcatenate() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let secondSubj = PassthroughSubject<String, Error>()

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = Publishers.Concatenate(prefix: firstSubj, suffix: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("first-2")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("second-1")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("second-2")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("third-1")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("third-2")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        secondSubj.send("final-2")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1", "final-2"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        secondSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1", "final-2"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testConcatenateSecondFinishedFirst() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let secondSubj = PassthroughSubject<String, Error>()

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = Publishers.Concatenate(prefix: firstSubj, suffix: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("first-2")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // even though second finished first, the first publisher can continue to send values
        secondSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("second-1")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("third-1")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testConcatenateSecondErroredFirst() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let secondSubj = PassthroughSubject<String, Error>()

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = Publishers.Concatenate(prefix: firstSubj, suffix: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("first-2")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // even though second errored, the first publisher can continue to send values
        secondSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("second-1")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("third-1")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // when the first publisher finishes, the error is propagated
        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testConcatenateFirstErrored() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let secondSubj = PassthroughSubject<String, Error>()

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = Publishers.Concatenate(prefix: firstSubj, suffix: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("first-2")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // when the first subject sends an error, it terminates the whole thing
        firstSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrependWithPublisher() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        let secondSubj = PassthroughSubject<String, Error>()

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = secondSubj
            .prepend(firstSubj) // aka Concatenate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses.count, 0)
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("first-2")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("second-1")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("second-2")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("third-1")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // all values from secondSubj will be ignored until first subject sends finished
        secondSubj.send("third-2")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        secondSubj.send("final-2")
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1", "final-2"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        secondSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1", "third-1", "final-2"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrependWithSequence() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prepend(["one", "two"])
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, ["one", "two"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["one", "two", "first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["one", "two", "first-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrependWithSingleValue() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prepend("singlevalue")
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, ["singlevalue"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["singlevalue", "first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["singlevalue", "first-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrefix() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prefix(2) // only two values published will propagate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("first-1")
        XCTAssertEqual(responses, ["first-1"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("second-1")
        // pipeline terminates after second value with `.prefix(2)`
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("third-1")
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["first-1", "second-1"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrefixWhile() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prefix { upstreamValue -> Bool in
                upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("one")
        // pipeline terminates after prefixWhile triggers true
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("-two-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testTryPrefixWhile() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .tryPrefix { upstreamValue -> Bool in
                if upstreamValue == "boom" {
                    throw TestExampleError.invalidValue
                }
                return upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("one")
        // pipeline terminates after prefixWhile triggers true
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("-two-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testTryPrefixWhileError() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .tryPrefix { upstreamValue -> Bool in
                if upstreamValue == "boom" {
                    throw TestExampleError.invalidValue
                }
                return upstreamValue.count > 3
            }
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("boom")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrefixUntilOutput() {
        let firstSubj = PassthroughSubject<String, Error>()
        let secondSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prefix(untilOutputFrom: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        secondSubj.send("one")
        // pipeline terminates after prefixUntilOutput triggers true
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrefixUntilOutputFirstError() {
        let firstSubj = PassthroughSubject<String, Error>()
        let secondSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prefix(untilOutputFrom: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertTrue(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testPrefixUntilOutputSecondError() {
        let firstSubj = PassthroughSubject<String, Error>()
        let secondSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .prefix(untilOutputFrom: secondSubj)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // values allowed through until prefix condition is triggered
        firstSubj.send("-initial-")
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        // triggering an error on the Prefix publisher doesn't ever trigger the prefix, and leaves the pipeline operational
        secondSubj.send(completion: Subscribers.Completion.failure(TestExampleError.invalidValue))
        XCTAssertEqual(responses, ["-initial-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("-second-")
        XCTAssertEqual(responses, ["-initial-", "-second-"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(responses, ["-initial-", "-second-"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testOutput() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .output(at: 3) // selection is 0-indexed, so this will select the 4th item published
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("one")
        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("two")
        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("three")
        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("four")
        XCTAssertEqual(responses, ["four"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("five")
        XCTAssertEqual(responses, ["four"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }

    func testOutputWithRange() {
        let firstSubj = PassthroughSubject<String, Error>()
        // no initial value is propagated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = firstSubj
            .output(in: 2 ... 3) // range selection is 0-indexed, so this will select the 3rd and 4th item published
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                terminatedStream = true
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    errorReceived = true
                    print("received error: ", anError)
                }
            }, receiveValue: { responseValue in
                responses.append(responseValue)
                print(".sink() data received \(responseValue)")
            })

        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("one")
        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("two")
        XCTAssertEqual(responses, [])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("three")
        XCTAssertEqual(responses, ["three"])
        XCTAssertFalse(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("four")
        XCTAssertEqual(responses, ["three", "four"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        firstSubj.send("five")
        XCTAssertEqual(responses, ["three", "four"])
        XCTAssertTrue(terminatedStream)
        XCTAssertFalse(errorReceived)

        XCTAssertNotNil(cancellable)
    }
}
