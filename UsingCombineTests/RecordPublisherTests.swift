//
//  RecordTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 2/29/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class RecordTests: XCTestCase {
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

    func testRecordInitializer() {
        let expectation = XCTestExpectation(description: debugDescription)

        // creates a recording
        let x = Record<String, Never> { example in

            // example : type is Record<String, Never>.Recording
            example.receive("one")
            example.receive("two")
            example.receive("three")
            example.receive(completion: .finished)
        }
        // x : Record<String, Never>

        XCTAssertNotNil(x)
        XCTAssertNotNil(x.recording)

        XCTAssertEqual(x.recording.output.count, 3)

        // record can be used directly as a publisher
        let cancellable = x.sink(receiveCompletion: { err in
            print(".sink() received the completion: ", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(".sink() received value: ", value)
        })
        wait(for: [expectation], timeout: 5.0)

        XCTAssertNotNil(cancellable)
    }

    func testRecordInitializationFromRecord() {
        // creates a recording
        let firstRecord = Record<String, Never> { example in
            example.receive("one")
            example.receive("two")
            example.receive("three")
            example.receive(completion: .finished)
        }

        XCTAssertNotNil(firstRecord)
        XCTAssertNotNil(firstRecord.recording)

        XCTAssertEqual(firstRecord.recording.output.count, 3)
        XCTAssertEqual(firstRecord.recording.completion, Subscribers.Completion<Never>.finished)

        // record can be used directly as a publisher
        // create a new recording from the original
        let secondRecord = Record(recording: firstRecord.recording)
        // XCTAssertEqual(firstRecord.recording, secondRecord.recording) - can't arrange this as Record/Recording isn't equatable
        XCTAssertEqual(firstRecord.recording.output, secondRecord.recording.output)
        XCTAssertEqual(firstRecord.recording.completion, secondRecord.recording.completion)
    }

    func testRecordInitializerAlt() {
        let expectation = XCTestExpectation(description: debugDescription)

        let y = Record<String, Never>(output: ["one", "two", "three"], completion: .finished)

        XCTAssertNotNil(y)
        XCTAssertNotNil(y.recording)

        XCTAssertEqual(y.recording.output.count, 3)

        let msTimeFormatter = DateFormatter()
        msTimeFormatter.dateFormat = "[HH:mm:ss.SSSS] "

        // record can be used directly as a publisher
        let cancellable = y.sink(receiveCompletion: { err in
            print(msTimeFormatter.string(from: Date()) + ".sink() received the completion: ", String(describing: err))
            expectation.fulfill()
        }, receiveValue: { value in
            print(msTimeFormatter.string(from: Date()) + ".sink() received value: ", value)
        })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testRecordEncodeDecodeWithFailureType() {
        // creates a recording
        let originalRecord = Record<String, TestFailureCondition> { example in
            // example is of type Record<String, TestFailureCondition>.Recording
            example.receive("one")
            example.receive("two")
            example.receive("three")
            example.receive(completion: .failure(.invalidServerResponse))
        }
        // originalRecord : Record<String, TestFailureCondition>
        // originalRecord.recording : Record<String, TestFailureCondition>.Recording

        let jencoder = JSONEncoder()
        if let encoded = try? jencoder.encode(originalRecord) {
            // encoded is of type Data, so lets convert this into a string with UTF8 encoding:
            if let json = String(data: encoded, encoding: .utf8) {
                // print(json)
                XCTAssertEqual(json,
                               """
                               {"recording":{"completion":{"success":false,"error":{"invalidServerResponse":null}},"output":["one","two","three"]}}
                               """)
            }

            let jdecoder = JSONDecoder()
            do {
                // Record<Output, Failure> vs Record<Output, Failure>.Recording
                let foo = try jdecoder.decode(Record<String, TestFailureCondition>.self, from: encoded)
                print("decoded data: ", foo)
                XCTAssertNotNil(foo)
                XCTAssertEqual(foo.recording.output.count, 3)
                // XCTAssertEqual(foo, originalRecord)
            } catch {
                XCTFail("Unexpected error decoding: \(error)")
            }
        }

        XCTAssertNotNil(originalRecord)
        XCTAssertNotNil(originalRecord.recording)
        XCTAssertEqual(originalRecord.recording.output.count, 3)
    }

    func testRecordEncodeDecodeWithCompletion() {
        // creates a recording
        let originalRecord = Record<String, TestFailureCondition> { example in
            example.receive("one")
            example.receive("two")
            example.receive("three")
            example.receive(completion: .finished)
        }

        let jencoder = JSONEncoder()
        if let encoded = try? jencoder.encode(originalRecord) {
            // encoded is of type Data, so lets convert this into a string with UTF8 encoding:
            if let json = String(data: encoded, encoding: .utf8) {
                print(json)
                XCTAssertEqual(json,
                               """
                               {"recording":{"completion":{"success":true},"output":["one","two","three"]}}
                               """)
            }

            let jdecoder = JSONDecoder()
            do {
                let foo = try jdecoder.decode(Record<String, TestFailureCondition>.self, from: encoded)
                print("decoded data: ", foo)
                XCTAssertNotNil(foo)
                XCTAssertEqual(foo.recording.output.count, 3)
                // XCTAssertEqual(foo, originalRecord)  - can't arrange this, as Record<> isn't Equatable
            } catch {
                XCTFail("Unexpected error decoding: \(error)")
            }
        }

        XCTAssertNotNil(originalRecord)
        XCTAssertNotNil(originalRecord.recording)
        XCTAssertEqual(originalRecord.recording.output.count, 3)
    }
}
