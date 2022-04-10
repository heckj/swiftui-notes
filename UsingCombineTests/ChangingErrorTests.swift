//
//  ChangingErrorTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 12/15/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class ChangingErrorTests: XCTestCase {
    enum TestExampleError: Error {
        case example
    }

    enum APIError: Error, LocalizedError {
        case unknown, apiError(reason: String), parserError(reason: String), networkError(from: URLError)

        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case let .apiError(reason), let .parserError(reason):
                return reason
            case let .networkError(from):
                return from.localizedDescription
            }
        }
    }

    func fetch(url: URL) -> AnyPublisher<Data, APIError> {
        let request = URLRequest(url: url)

        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                if httpResponse.statusCode == 401 {
                    throw APIError.apiError(reason: "Unauthorized")
                }
                if httpResponse.statusCode == 403 {
                    throw APIError.apiError(reason: "Resource forbidden")
                }
                if httpResponse.statusCode == 404 {
                    throw APIError.apiError(reason: "Resource not found")
                }
                if 405 ..< 500 ~= httpResponse.statusCode {
                    throw APIError.apiError(reason: "client error")
                }
                if 500 ..< 600 ~= httpResponse.statusCode {
                    throw APIError.apiError(reason: "server error")
                }
                return data
            }
            .mapError { error in
                // if it's our kind of error already, we can return it directly
                if let error = error as? APIError {
                    return error
                }
                // if it is a TestExampleError, convert it into our new error type
                if error is TestExampleError {
                    return APIError.parserError(reason: "Our example error")
                }
                // if it is a URLError, we can convert it into our more general error kind
                if let urlerror = error as? URLError {
                    return APIError.networkError(from: urlerror)
                }
                // if all else fails, return the unknown error condition
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }

    func testMapError() {
        let expectation = XCTestExpectation(description: debugDescription)
        let publisher = Fail<String, ChangingErrorTests.TestExampleError>(error: TestExampleError.example)

        // Making a publisher that's constrained to fail is causing some semnatic compiler warnings below,
        // as the logic choices are rather predetermined by the choice of publisher. I'm leaving the logic
        // as it is because I think it's more representative of an actual use case as opposed to our specific
        // test case example while illustrates the operation of mapError
        let cancellable = publisher
            .mapError { error -> ChangingErrorTests.APIError in
                // if it's our kind of error already, we can return it directly
                if let error = error as? APIError {
                    return error
                }
                // if it is a URLError, we can convert it into our more general error kind
                if let urlerror = error as? URLError {
                    return APIError.networkError(from: urlerror)
                }
                // if all else fails, return the unknown error condition
                return APIError.unknown
            }.sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
                    if !(anError is APIError) {
                        // fail if this is anything BUT an APIError
                        XCTFail()
                    }
                }
                expectation.fulfill()
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                XCTFail()
            })

        wait(for: [expectation], timeout: 3.0)
        XCTAssertNotNil(cancellable)
    }

    func testReplaceError() {
        let expectation = XCTestExpectation(description: debugDescription)
        let publisher = Fail<String, ChangingErrorTests.TestExampleError>(error: TestExampleError.example)

        let cancellable = publisher
            .replaceError(with: "foo")
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                    XCTFail()
                }
                expectation.fulfill()
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                XCTAssertEqual(responseValue, "foo")
            })

        wait(for: [expectation], timeout: 3.0)
        XCTAssertNotNil(cancellable)
    }
}
