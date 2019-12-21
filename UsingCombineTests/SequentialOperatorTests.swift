//
//  SequentialOperatorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/21/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class SequentialOperatorTests: XCTestCase {

    enum TestExampleError: Error {
        case invalidValue
    }

    func testFirst() {
        let passSubj = PassthroughSubject<String, Never>()
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .first { (incomingobject) -> Bool in
            return incomingobject.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .first { (incomingobject) -> Bool in
            return incomingobject.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryFirst { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryFirst { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
        .tryFirst { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                errorReceived = true
                break
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
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .last { (incomingobject) -> Bool in
            return incomingobject.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .last { (incomingobject) -> Bool in
            return incomingobject.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryLast { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryLast { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
        .tryLast { (incomingobject) -> Bool in
            if (incomingobject == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                errorReceived = true
                break
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
        // no initial value is propogated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Never>()
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Error>()
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                receivedError = true
                break
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

        XCTAssertNotNil(cancellable)
    }

    func testDropUntilOutputFinished() {
        let passSubj = PassthroughSubject<String, Error>()
        // no initial value is propogated from a PassthroughSubject

        let triggerSubj = PassthroughSubject<Int, Error>()
        // no initial value is propogated from a PassthroughSubject

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
            case .failure(let anError):
                print("received error: ", anError)
                receivedError = true
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .drop { upstreamValue -> Bool in
            return upstreamValue.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        XCTAssertEqual(responses, ["abc","xyz"])
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .drop { upstreamValue -> Bool in
            return upstreamValue.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .drop { upstreamValue -> Bool in
            return upstreamValue.count > 3
        }
        .sink(receiveCompletion: { completion in
            print(".sink() received the completion", String(describing: completion))
            terminatedStream = true
            switch completion {
            case .finished:
                break
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryDrop { upstreamValue -> Bool in
            if (upstreamValue == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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
        XCTAssertEqual(responses, ["abc","xyz"])
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false
        var errorReceived = false

        let cancellable = passSubj
        .tryDrop { upstreamValue -> Bool in
            if (upstreamValue == "boom") {
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
            case .failure(let anError):
                errorReceived = true
                print("received error: ", anError)
                break
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
        // no initial value is propogated from a PassthroughSubject

        var responses = [String]()
        var terminatedStream = false

        let cancellable = passSubj
        .tryDrop { upstreamValue -> Bool in
            if (upstreamValue == "boom") {
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
            case .failure(let anError):
                print("received error: ", anError)
                break
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

}
