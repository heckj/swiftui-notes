//
//  SwitchAndFlatMapPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class SwitchAndFlatMapPublisherTests: XCTestCase {
    // matching the data structure returned from ip.jsontest.com
    struct IPInfo: Codable {
        var ip: String
    }

    enum TestFailureCondition: Error {
        case invalidServerResponse
    }

    func testBasicFlatMap_String_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Never>()

        let cancellable = simpleControlledPublisher
            .flatMap { _ in // takes a String in and returns a Publisher
                Just<String>("Alternate data")
                // flatMap returns a Publisher, where map returns <Input> - String in this case
            }
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                // this print adds into the console output:
                // .sink() received Alternate data
                // .sink() received Alternate data
                // .sink() received Alternate data
                // .sink() received Alternate data
            })

        let oneFish = "onefish"
        let twoFish = "twofish"
        let redFish = "redfish"
        let blueFish = "bluefish"

        simpleControlledPublisher.send(oneFish)
        simpleControlledPublisher.send(twoFish)
        simpleControlledPublisher.send(redFish)
        simpleControlledPublisher.send(blueFish)
        XCTAssertNotNil(cancellable)
    }

    func testBasicFlatMapWithBackdoorPublisher_String_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Never>()

        let backDoorPublisher = PassthroughSubject<String, Never>()

        let cancellable = simpleControlledPublisher
            .flatMap { _ -> AnyPublisher<String, Never> in // takes a String in and returns a Publisher
                backDoorPublisher.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            //            .print()
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")

            })

        let oneFish = "onefish"
        let twoFish = "twofish"
        let redFish = "redfish"
        let blueFish = "bluefish"

        simpleControlledPublisher.send(oneFish)
        backDoorPublisher.send("first response")
        // backDoorPublisher.send(completion: .finished)
        // with the above line uncommented, we only receive:
        //    ** .sink() received first response
        //    ** .sink() received second response
        // and the pipeline appears to be terminated is terminated

        simpleControlledPublisher.send(twoFish)
        backDoorPublisher.send("second response")

        // simpleControlledPublisher.send(completion: .finished)
        // with the above line uncommented, the original pipeline is terminated, but the
        // backDoor pipelines put into place by the flatmap are still completely active to downstream
        // subscribers. Console output:
        // ** .sink() received first response
        // ** .sink() received second response
        // ** .sink() received second response
        // ** .sink() received third response
        // ** .sink() received third response
        // ** .sink() received fourth response
        // ** .sink() received fourth response
        // ** .sink() received the completion: finished

        simpleControlledPublisher.send(redFish)
        backDoorPublisher.send("third response")
        simpleControlledPublisher.send(blueFish)
        backDoorPublisher.send("fourth response")
        backDoorPublisher.send(completion: .finished)

        simpleControlledPublisher.send(blueFish)
        backDoorPublisher.send("fifth response")
        XCTAssertNotNil(cancellable)
        // based on this output, flatMap is adding a publisher for every element in the original stream
        // and each publisher that's created gets added - so if the original stream had 3 events flow through,
        // there could be 3 active publishers sending data
        // ** .sink() received first response
        // ** .sink() received second response
        // ** .sink() received second response
        // ** .sink() received third response
        // ** .sink() received third response
        // ** .sink() received third response
        // ** .sink() received fourth response
        // ** .sink() received fourth response
        // ** .sink() received fourth response
        // ** .sink() received fourth response
    }

    func testBasicFlatMapFallback_Data_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<Data, Never>()

        let cancellable = simpleControlledPublisher
            .flatMap { value in // takes a String in and returns a Publisher
                Just<Data>(value)
                    .decode(type: IPInfo.self, decoder: JSONDecoder())
                    .catch { _ in
                        Just(IPInfo(ip: "8.8.8.8"))
                    }
            }
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                // this print adds into the console output:
                // .sink() received IPInfo(ip: "1.2.3.4")
                // .sink() received IPInfo(ip: "192.168.1.1")
                // .sink() received IPInfo(ip: "8.8.8.8")
                // .sink() received IPInfo(ip: "192.168.0.1")
                // .sink() received the completion: finished
            })

        let oneFish = "{ \"ip\": \"1.2.3.4\" }".data(using: .utf8)
        let twoFish = "{ \"ip\": \"192.168.1.1\" }".data(using: .utf8)
        let redFish = "Opps, crap - no JSON here".data(using: .utf8)
        let blueFish = "{ \"ip\": \"192.168.0.1\" }".data(using: .utf8)

        simpleControlledPublisher.send(oneFish!)
        simpleControlledPublisher.send(twoFish!)
        simpleControlledPublisher.send(redFish!)
        simpleControlledPublisher.send(blueFish!)
        simpleControlledPublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testBasicFlatMapFallback_Data_ErrorPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<Data, Error>()

        let cancellable = simpleControlledPublisher
            .flatMap { value in // takes a String in and returns a Publisher
                Just(value)
                    .decode(type: IPInfo.self, decoder: JSONDecoder())
                //                .catch { _ in
                //                    return Publishers.Just(IPInfo(ip: "8.8.8.8"))
                //                }
            }
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                // this print adds into the console output:
                // .sink() received IPInfo(ip: "1.2.3.4")
                // .sink() received IPInfo(ip: "192.168.1.1")
                // .sink() received IPInfo(ip: "8.8.8.8")
                // .sink() received IPInfo(ip: "192.168.0.1")
                // .sink() received the completion: finished
            })

        let oneFish = "{ \"ip\": \"1.2.3.4\" }".data(using: .utf8)
        let twoFish = "{ \"ip\": \"192.168.1.1\" }".data(using: .utf8)
        let redFish = "Opps, crap - no JSON here".data(using: .utf8)
        let blueFish = "{ \"ip\": \"192.168.0.1\" }".data(using: .utf8)

        simpleControlledPublisher.send(oneFish!)
        simpleControlledPublisher.send(twoFish!)
        simpleControlledPublisher.send(redFish!)
        simpleControlledPublisher.send(blueFish!)
        simpleControlledPublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testSwitchToLatest() {
        func APIProxyExample(someString: String) -> AnyPublisher<[String], Never> {
            // an example function that might act akin to an API call that returns a publisher with a response.

            // in this case we just return a publisher with the input value inside a list
            return Just([someString]).eraseToAnyPublisher()
        }

        let simpleSubjectPublisher = PassthroughSubject<String, Never>()

        let cancellable = simpleSubjectPublisher
            .map { stringValue in
                APIProxyExample(someString: stringValue)
            }
            .switchToLatest()
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                case .finished:
                    break
                }
            }, receiveValue: { listOfStrings in
                print(".sink() received ", listOfStrings)
                XCTAssertEqual(listOfStrings.first, "onefish")
                XCTAssertEqual(listOfStrings.count, 1)
            })

        simpleSubjectPublisher.send("onefish") // onefish will pass the filter
        simpleSubjectPublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertNotNil(cancellable)
    }

    func testAndreiKuzmaSwitchToLatest() {
        // from swift forums post highlighting a failure during IOS 13.4 development
        let canceled = expectation(description: "Should be canceled")
        let finished = expectation(description: "Should be Finished")

        var valuesCount = 0
        let subject = PassthroughSubject<Void, Never>()
        let delay: TimeInterval = 1
        let scheduler = DispatchQueue(label: "testSwitchToLatest")

        var cancellable: AnyCancellable? = subject.map { _ in
            Just(()).delay(
                for: .seconds(delay),
                scheduler: scheduler
            ).handleEvents(
                receiveSubscription: { _ in
                    print("Started")
                },
                receiveCancel: {
                    print("Canceled")
                    canceled.fulfill()
                }
            )
        }.switchToLatest().sink(
            receiveCompletion: { _ in
                finished.fulfill()
            },
            receiveValue: { _ in
                valuesCount += 1
            }
        )

        subject.send(())
        subject.send(())

        // If deadline > .now() + delay than you will receive completion otherwise not
        let deadline: DispatchTime = .now() + delay / 2
        scheduler.asyncAfter(deadline: deadline) {
            subject.send(completion: .finished)
        }

        wait(for: [canceled, finished], timeout: 5)
        cancellable?.cancel()
        cancellable = nil

        XCTAssert(valuesCount == 1)
    }

    func testShaiMishaliSwitchToLatest() {
        // from https://forums.swift.org/t/confused-about-behaviour-of-switchtolatest-in-combine/29914/28
        var subscription: AnyCancellable!
        let expect = expectation(description: "tester")
        var outerCompleted = false
        subscription = Just("trigger")
            .map { _ -> AnyPublisher<Void, Never> in
                Timer
                    .publish(every: 0.1, on: RunLoop.current, in: .common)
                    .autoconnect()
                    .map { _ in () }
                    .prefix(8)
                    .handleEvents(receiveOutput: { _ in print("inner value") },
                                  receiveCompletion: { print("inner completed: \($0)") })
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .print("post-stl")
            .sink(
                receiveCompletion: {
                    print("completed \($0)")
                    outerCompleted = true
                    expect.fulfill()
                },
                receiveValue: { _ in print("value") }
            )
        wait(for: [expect], timeout: 2)
        XCTAssertTrue(outerCompleted)
        XCTAssertNotNil(subscription)
    }

    func testSwitchToLatestReturningTwoResults() {
        func APIDifferentProxyExample() -> AnyPublisher<String, Never> {
            // an example function that might act akin to an API call that returns a publisher with a response.

            // this "api response" provides more than a one-shot response.
            // The publisher generates more than one response - two in this case,
            // using the Sequence publisher
            return Publishers.Sequence(sequence: ["redfish", "bluefish"])
                .eraseToAnyPublisher()
        }

        var countOfResponses = 0
        let simpleSubjectPublisher = PassthroughSubject<String, Never>()

        let cancellable = simpleSubjectPublisher
            .map { _ in
                APIDifferentProxyExample()
            }
            .switchToLatest()
            .print(debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case let .failure(anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                case .finished:
                    break
                }
            }, receiveValue: { aValue in
                print(".sink() received ", aValue)
                countOfResponses += 1
            })

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(countOfResponses, 0)
        simpleSubjectPublisher.send("trigger")
        XCTAssertEqual(countOfResponses, 2)
        simpleSubjectPublisher.send("anotherTrigger")
        XCTAssertEqual(countOfResponses, 4)
        simpleSubjectPublisher.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(countOfResponses, 4)
    }
}
