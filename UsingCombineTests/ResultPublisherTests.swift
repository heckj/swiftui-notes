//
//  ResultPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 3/1/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class ResultPublisherTests: XCTestCase {

    enum TestFailureCondition: Error, Codable, CodingKey
    {
        // reading on codable enums: https://www.objc.io/blog/2018/01/23/codable-enums/
        // and https://medium.com/@hllmandel/codable-enum-with-associated-values-swift-4-e7d75d6f4370

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: TestFailureCondition.self)

            // If the error enum was set up with associated values, we'd need to twiddle the
            // encode/decode a bit along these lines:
            //
            // let value =  try container.decode(TestFailureCondition.self, forKey: .invalidServerResponse)
            // self = .left(leftValue)

            if (try container.decodeNil(forKey: .invalidServerResponse)) {
                self = .invalidServerResponse
            } else if (try container.decodeNil(forKey: .aDifferentFailure)) {
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
        let expectation = XCTestExpectation(description: self.debugDescription)

        // borrowed from Paul's article on Result
        // https://www.hackingwithswift.com/articles/161/how-to-use-result-in-swift
        // to make a function that creates a result instance
        func generateRandomNumber(maximum: Int) -> Result<Int, TestFailureCondition> {
            if maximum < 0 {
                // creating a range below 0 will crash, so refuse
                return .failure(.aDifferentFailure)
            } else {
                let number = Int.random(in: 0...maximum)
                return .success(number)
            }
        }

        // any Result instance is also a publisher
        let foo = generateRandomNumber(maximum: 10).publisher

        // record can be used directly as a publisher
        let cancellable = foo.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })
        wait(for: [expectation], timeout: 5.0)

        XCTAssertNotNil(cancellable)
    }

}
