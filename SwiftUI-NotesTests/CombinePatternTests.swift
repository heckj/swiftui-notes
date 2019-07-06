//
//  CombinePatternTests.swift
//  SwiftUI-NotesTests
//
//  Created by Joseph Heck on 6/21/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class CombinePatternTests: XCTestCase {

    enum testFailureCondition: Error {
        case invalidServerResponse
    }
    // matching the data structure returned from ip.jsontest.com
    struct IPInfo: Codable {
            var ip: String
    }

    func testDeadSimpleChain() {
        let simplePublisher = PassthroughSubject<String, Error>()

        let _ = simplePublisher
            .print()
            // the result of adding in .print() to this chain is the following additional console output
            //        receive subscription: (PassthroughSubject)
            //        request unlimited
            //        receive value: (firstStringValue)
            //        receive value: (secondStringValue)
            //        receive error: (invalidServerResponse)
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                // this print adds into the console output:
                //        .sink() received firstStringValue
                //        .sink() received secondStringValue
                //        .sink() caught the failure failure(SwiftUI_NotesTests.CombinePatternTests.testFailureCondition.invalidServerResponse)
            })

        simplePublisher.send("firstStringValue")
        simplePublisher.send("secondStringValue")
        simplePublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))

        // this data will never be seen by anything in the pipeline above because we've already sent a completion
        simplePublisher.send(completion: Subscribers.Completion.finished)

// the full console output from this test
//        receive subscription: (PassthroughSubject)
//        request unlimited
//        receive value: (firstStringValue)
//        .sink() received firstStringValue
//        receive value: (secondStringValue)
//        .sink() received secondStringValue
//        receive error: (invalidServerResponse)
//        .sink() caught the failure failure(SwiftUI_NotesTests.CombinePatternTests.testFailureCondition.invalidServerResponse)

    }

    func testDeadSimpleChainAssertNoFailure() {
        let simplePublisher = PassthroughSubject<String, Error>()

        let _ = simplePublisher
            .assertNoFailure("What could possibly go wrong?")
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
            })

        simplePublisher.send("oneValue")
        simplePublisher.send("twoValue")

        // uncomment this next line to see the failure mode:
        // simplePublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))
        simplePublisher.send(completion: .finished)
    }

    func testDeadSimpleChainCatch() {
        let simplePublisher = PassthroughSubject<String, Error>()

        let _ = simplePublisher
            .catch { err in
                // must return a Publisher
                return Just("replacement value")
            }
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
            })

        simplePublisher.send("oneValue")
        simplePublisher.send("twoValue")
        simplePublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))
        simplePublisher.send("redValue")
        simplePublisher.send("blueValue")
        simplePublisher.send(completion: .finished)

        // the output of this test is:
        // .sink() received oneValue
        // .sink() received twoValue
        // .sink() received replacement value
        // .sink() received the completion: finished
        // NOTE(heckj) catch intercepts the whole chain and replaces it with what you return.
        // In this case, it's the Just convenience publisher, which in turn immediately sends a "finish" when it's done.

    }


    func testBasicFlatMap_String_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Never>()

        let _ = simpleControlledPublisher
            .flatMap { someValue in // takes a String in and returns a Publisher
                return Just<String>("Alternate data")
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

    }

    func testBasicFlatMapWithBackdoorPublisher_String_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Never>()

        let backDoorPublisher = PassthroughSubject<String, Never>()

        let _ = simpleControlledPublisher
            .flatMap { someValue -> AnyPublisher<String, Never> in // takes a String in and returns a Publisher
                return backDoorPublisher.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
//            .print()
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
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
            //** .sink() received first response
            //** .sink() received second response
            //** .sink() received second response
            //** .sink() received third response
            //** .sink() received third response
            //** .sink() received fourth response
            //** .sink() received fourth response
            //** .sink() received the completion: finished

        simpleControlledPublisher.send(redFish)
        backDoorPublisher.send("third response")
        simpleControlledPublisher.send(blueFish)
        backDoorPublisher.send("fourth response")
        backDoorPublisher.send(completion: .finished)

        simpleControlledPublisher.send(blueFish)
        backDoorPublisher.send("fifth response")

        // based on this output, flatMap is adding a publisher for every element in the original stream
        // and each publisher that's created gets added - so if the original stream had 3 events flow through,
        // there could be 3 active publishers sending data
        //** .sink() received first response
        //** .sink() received second response
        //** .sink() received second response
        //** .sink() received third response
        //** .sink() received third response
        //** .sink() received third response
        //** .sink() received fourth response
        //** .sink() received fourth response
        //** .sink() received fourth response
        //** .sink() received fourth response

    }

    func testBasicFlatMapFallback_Data_NeverPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<Data, Never>()

        let _ = simpleControlledPublisher
            .flatMap { value in // takes a String in and returns a Publisher
                return Just<Data>(value)
                .decode(type: IPInfo.self, decoder: JSONDecoder())
                .catch { _ in
                    return Just(IPInfo(ip: "8.8.8.8"))
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

    }

    func testBasicFlatMapFallback_Data_ErrorPublisher() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<Data, Error>()

        let _ = simpleControlledPublisher
            .flatMap { value in // takes a String in and returns a Publisher
                return Just(value)
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

    }

    func testRetryOperatorWithPassthroughSubject() {
        // setup
        let simpleControlledPublisher = PassthroughSubject<String, Error>()

        let _ = simpleControlledPublisher
            .print()
            .retry(1)
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
        simpleControlledPublisher.send(twoFish)

        // with an error response, this prints two results and hangs...
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))

        // with a completion, this prints two results and ends
        //simpleControlledPublisher.send(completion: .finished)

        simpleControlledPublisher.send(redFish)
        simpleControlledPublisher.send(blueFish)
    }

    func testRetryOperatorWithCurrentValueSubject() {
        // setup
        let simpleControlledPublisher = CurrentValueSubject<String, Error>("initial value")

        let _ = simpleControlledPublisher
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })

        let oneFish = "onefish"

        simpleControlledPublisher.send(oneFish)
        // with an error response, this prints two results and hangs...
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))

        // with a completion, this prints two results and ends
        //simpleControlledPublisher.send(completion: .finished)

//        output:
//        (1)>: receive subscription: (CurrentValueSubject)
//        (2)>: receive subscription: (Retry)
//        (2)>: request unlimited
//        (1)>: request unlimited
//        (1)>: receive value: (initial value)
//        (2)>: receive value: (initial value)
//        ** .sink() received initial value
//        (1)>: receive value: (onefish)
//        (2)>: receive value: (onefish)
//        ** .sink() received onefish
//        (1)>: receive finished
//        (2)>: receive finished
//        ** .sink() received the completion: finished
    }

    func testRetryWithOneShotJustPublisher() {
        // setup
        let _ = Just<String>("yo")
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })
//        output:
//        (1)>: receive subscription: (Just)
//        (2)>: receive subscription: (Retry)
//        (2)>: request unlimited
//        (1)>: request unlimited
//        (1)>: receive value: (yo)
//        (2)>: receive value: (yo)
//        ** .sink() received yo
//        (1)>: receive finished
//        (2)>: receive finished
//        ** .sink() received the completion: finished

    }

    func testRetryWithOneShotFailPublisher() {
        // setup
        let _ = Publishers.Fail(outputType: String.self, failure: testFailureCondition.invalidServerResponse)
            .print("(1)>")
            .retry(3)
            .print("(2)>")
            .sink(receiveCompletion: { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(" ** .sink() received \(stringValue)")
            })
//        output:
//        (1)>: receive subscription: (Empty)
//        (1)>: receive error: (invalidServerResponse)
//        (1)>: receive subscription: (Empty)
//        (1)>: receive error: (invalidServerResponse)
//        (1)>: receive subscription: (Empty)
//        (1)>: receive error: (invalidServerResponse)
//        (1)>: receive subscription: (Empty)
//        (1)>: receive error: (invalidServerResponse)
//        (2)>: receive error: (invalidServerResponse)
//        ** .sink() received the completion: failure(SwiftUI_NotesTests.CombinePatternTests.testFailureCondition.invalidServerResponse)
//        (2)>: receive subscription: (Retry)
//        (2)>: request unlimited

    }


    func testFutureSignatureWithoutErasure() {
        let x = PassthroughSubject<String, Never>()
            .flatMap { name in
                return Future<String, Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    return "\(result) foo"
                }
        }
        
        print(x)
    }
}
