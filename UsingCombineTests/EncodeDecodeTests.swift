//
//  EncodeDecodeTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/6/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class EncodeDecodeTests: XCTestCase {
    let testUrlString = "https://postman-echo.com/time/valid?timestamp=2016-10-10"
    // checks the validity of a timestamp - this one should return {"valid":true}
    // matching the data structure returned from https://postman-echo.com/time/valid
    fileprivate struct PostmanEchoTimeStampCheckResponse: Codable {
        let valid: Bool
    }

    func testSimpleDecode() {
        // setup
        let dataProvider = PassthroughSubject<Data, Never>()

        let cancellable = dataProvider
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            // validate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail("shouldn't receive a failure with this sample")
                }
            }, receiveValue: { postmanResponse in
                XCTAssertNotNil(postmanResponse)
                print(".sink() data received \(postmanResponse)")
                XCTAssertTrue(postmanResponse.valid)
            })

        dataProvider.send(Data("{\"valid\":true}".utf8))
        XCTAssertNotNil(cancellable)
    }

    func testSimpleDecodeFailure() {
        // setup
        let dataProvider = PassthroughSubject<Data, Never>()

        let cancellable = dataProvider
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            // validate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("shouldn't receive a finished completion with this sample")
                case let .failure(anError):
                    print("received error: ", anError.localizedDescription)
                    XCTAssertEqual("The data couldn’t be read because it is missing.", anError.localizedDescription)
                    // there's a lot more information in the raw error
                    // Swift.DecodingError.keyNotFound(CodingKeys(stringValue: "valid", intValue: nil), Swift.DecodingError.Context(codingPath: [], debugDescription: "No value associated with key CodingKeys(stringValue: \"valid\", intValue: nil) (\"valid\").", underlyingError: nil)))
                }
            }, receiveValue: { postmanResponse in
                print(".sink() data received \(postmanResponse)")
                XCTFail("no values expected in failure scenario")
            })

        dataProvider.send(Data("{}".utf8))
        XCTAssertNotNil(cancellable)
    }

    func testSimpleEncode() {
        // setup
        let dataProvider = PassthroughSubject<PostmanEchoTimeStampCheckResponse, Never>()

        let cancellable = dataProvider
            .encode(encoder: JSONEncoder())
            // validate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail("shouldn't receive a failure with this sample")
                }
            }, receiveValue: { data in
                XCTAssertNotNil(data)
                print(".sink() data received \(data)")
                let stringRepresentation = String(data: data, encoding: .utf8)
                XCTAssertEqual("{\"valid\":false}", stringRepresentation)
            })

        dataProvider.send(PostmanEchoTimeStampCheckResponse(valid: false))
        XCTAssertNotNil(cancellable)
    }

    func testSimpleEncodeNil() {
        // setup
        let dataProvider = PassthroughSubject<PostmanEchoTimeStampCheckResponse?, Never>()

        let cancellable = dataProvider
            .encode(encoder: JSONEncoder())
            // validate
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("shouldn't receive a finished with this sample")
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail("shouldn't receive a finished with this sample")
                }
            }, receiveValue: { data in
                let resultingString = String(data: data, encoding: .utf8)
                XCTAssertEqual(resultingString, "null")
            })

        dataProvider.send(nil)
        XCTAssertNotNil(cancellable)
    }
}
