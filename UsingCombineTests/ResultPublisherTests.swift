//
//  ResultPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 3/1/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import CombineSchedulers
import XCTest

class ResultPublisherTests: XCTestCase {
    enum TestFailureCondition: Error, Codable, CodingKey {
        // reading on codable enums: https://www.objc.io/blog/2018/01/23/codable-enums/
        // and https://medium.com/@hllmandel/codable-enum-with-associated-values-swift-4-e7d75d6f4370

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: TestFailureCondition.self)

            // If the error enum was set up with associated values, we'd need to twiddle the
            // encode/decode a bit along these lines:
            //
            // let value =  try container.decode(TestFailureCondition.self, forKey: .invalidServerResponse)
            // self = .left(leftValue)

            if try container.decodeNil(forKey: .invalidServerResponse) {
                self = .invalidServerResponse
            } else if try container.decodeNil(forKey: .aDifferentFailure) {
                self = .aDifferentFailure
            } else {
                // default if nothing else worked
                self = .invalidServerResponse
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: TestFailureCondition.self)
            switch self {
            case .invalidServerResponse:
                try container.encodeNil(forKey: .invalidServerResponse)
            // If the error enum was set up with associated values, we'd need to twiddle the
            // encode/decode a bit along these lines:
            //
            // try container.encode("x", forKey: .invalidServerResponse)
            case .aDifferentFailure:
                try container.encodeNil(forKey: .aDifferentFailure)
            }
        }

        case invalidServerResponse
        case aDifferentFailure
    }

    func testResultPublisher() {
        let testScheduler = DispatchQueue.immediateScheduler
        // borrowed from Paul's article on Result
        // https://www.hackingwithswift.com/articles/161/how-to-use-result-in-swift
        // to make a function that creates a result instance
        func generateRandomNumber(maximum: Int) -> Result<Int, TestFailureCondition> {
            if maximum < 0 {
                // creating a range below 0 will crash, so refuse
                return .failure(.aDifferentFailure)
            } else {
                let number = Int.random(in: 0 ... maximum)
                return .success(number)
            }
        }

        // any Result instance is also a publisher
        let foo = generateRandomNumber(maximum: 10)
            .publisher
            .receive(on: testScheduler)

        // record can be used directly as a publisher
        let cancellable = foo.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))

        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })

        XCTAssertNotNil(cancellable)
    }

    func testConvertingPublisherToAResultPublisher() {
        let testScheduler = DispatchQueue.testScheduler
        var receivedValues: [String] = []
        var errorCount = 0
        // goal is to convert a Publisher<String, Error> into a Publisher<Result<String, Error>, Never>

        let victim = PassthroughSubject<String, Error>()

        let xyz: AnyCancellable = victim
            .receive(on: testScheduler)
            .map {
                Result<String, Error>.success($0)
            }
            .catch {
                Just(Result<String, Error>.failure($0))
            }
            .print("S ")
            .sink { aResult in
                print("we got ", aResult)
                do {
                    receivedValues.append(try aResult.get())
                } catch {
                    errorCount += 1
                }
            }

        XCTAssertNotNil(xyz)
        XCTAssertEqual(receivedValues.count, 0)
        XCTAssertEqual(errorCount, 0)
        victim.send("one")
        XCTAssertEqual(receivedValues.count, 0)
        XCTAssertEqual(errorCount, 0)
        testScheduler.advance(by: 1)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(errorCount, 0)

        victim.send(completion: Subscribers.Completion.failure(TestFailureCondition.invalidServerResponse))
        testScheduler.advance(by: 1)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(errorCount, 1)

        // sending the completion, even though caught, terminates the pipeline
        // so any further values don't go anywhere. So the above code *does* convert the output
        // type, but the result is that the pipeline basically becomes a one-shot scenario.
        // To use on any repeating structure, you'd need to do the trick where you wrap
        // this structure within a flatMap to generate one-shot publishers as you needed.

        victim.send("two")
        testScheduler.advance(by: 1)

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(errorCount, 1)

//        S : receive subscription: (Catch)
//        S : request unlimited
//        S : receive value: (success("one"))
//        we got  success("one")
//        S : receive value: (failure(TestFailureCondition(stringValue: "invalidServerResponse", intValue: nil)))
//        we got  failure(TestFailureCondition(stringValue: "invalidServerResponse", intValue: nil))
//        S : receive finished
    }
}
