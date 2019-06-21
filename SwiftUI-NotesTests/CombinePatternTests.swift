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

    var testURL: URL?

    enum testFailureCondition: Error {
        case invalidServerResponse
    }

    let testUrlString = "http://ip.jsontest.com"
    // this always returns data in the format of {"ip": "63.234.253.210"}

    override func setUp() {
        self.testURL = URL(string: testUrlString)
    }

    func testDeadSimpleChain() {
        let simplePublisher = PassthroughSubject<String, Error>()

        let _ = simplePublisher
            .print()
            .sink(receiveCompletion: { err in
            // XCTFail()
            print(".sink() caught the failure", String(describing: err))

        }, receiveValue: { stringValue in
            XCTAssertNotNil(stringValue)
            print(".sink() received \(stringValue)")

            // expecting this to fail, want to see what happens
            // XCTAssertEqual(stringValue, "foo") // and it does - throws two test exceptions for this test
        })

        simplePublisher.send("firstStringValue")
        simplePublisher.send("secondStringValue")
//        let aFailure = Subscribers.Completion<Failure: Error>
        // Cannot convert value of type 'CombinePatternTests.testFailureCondition.Type' to expected argument type 'Subscribers.Completion<Error>'
        simplePublisher.send(completion: Subscribers.Completion.failure(testFailureCondition.invalidServerResponse))

// test console output
//        receive subscription: (PassthroughSubject)
//        request unlimited
//        receive value: (firstStringValue)
//        .sink() received firstStringValue
//        receive value: (secondStringValue)
//        .sink() received secondStringValue
//        receive error: (invalidServerResponse)
//        .sink() caught the failure failure(SwiftUI_NotesTests.CombinePatternTests.testFailureCondition.invalidServerResponse)

    }
    func testAlternateDataTaskPublisherSetup() {
        // setup
        let myUrlRequest = URLRequest(url: testURL!)
        let myUrlSession = URLSession.shared
        let foo = URLSession.DataTaskPublisher(request: myUrlRequest, session: myUrlSession)
            .print()
//receive subscription: ((extension in Foundation):__C.NSURLSession.DataTaskPublisher.(unknown context at $10e337eb4).Inner<Combine.Publishers.Print<(extension in Foundation):__C.NSURLSession.DataTaskPublisher>.(unknown context at $10b75c24c).Inner<Combine.Subscribers.Sink<Combine.Publishers.Print<(extension in Foundation):__C.NSURLSession.DataTaskPublisher>>>>)
//request unlimited
            .sink(receiveCompletion: { err in
                // XCTFail()
                print("foo.sink() caught the failure", String(describing: err))

            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print("foo.sink() received \(stringValue)")
            })

        XCTAssertNotNil(foo) // shut up the compiler warning about unused variable
        //NOTE(heckj): chain is clearly set up, but unlimited subscription isn't receiving any values
    }

    func testSimpleURLDecodeChain() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: self.testURL!)
            .tryMap { data, response -> Data in
                print("tryMap executing")
                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        print(" >throwing invalidServerResponse")
                        throw testFailureCondition.invalidServerResponse
                }
                print(" >returning NSData")
                return data
        }
        // validate

        XCTAssertNotNil(remoteDataPublisher)

        // validate
        let _ = remoteDataPublisher
        .sink(receiveCompletion: { fini in
            print(".sink() received the completion", String(describing: fini))
            switch fini {
            case .finished: expectation.fulfill()
            case .failure: XCTFail()
            }
        }, receiveValue: { stringValue in
            XCTAssertNotNil(stringValue)
            print(".sink() received \(stringValue)")
        })

        wait(for: [expectation], timeout: 10.0)
        print("TEST COMPLETE")
        //NOTE(heckj): chain is clearly set up, but unlimited subscription isn't receiving any values
    }

    func testDataTaskPublisher() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: self.testURL!)
            // validate
            .sink(receiveCompletion: { err in
//                XCTFail(String(describing: err))
                print(".sink() caught the completion", String(describing: err))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                expectation.fulfill()
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 10.0)
    }

    func testDataTaskPublisherWithErrorMap() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: self.testURL!)
            .tryMap { data, response -> Data in
                print("tryMap executing")
                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        print(" >throwing invalidServerResponse")
                        throw testFailureCondition.invalidServerResponse
                }
                print(" >returning NSData")
                return data
            }
            // validate
            .sink(receiveCompletion: { err in
                //                XCTFail(String(describing: err))
                print(".sink() caught the completion", String(describing: err))
            }, receiveValue: { stringValue in
                XCTAssertNotNil(stringValue)
                print(".sink() received \(stringValue)")
                expectation.fulfill()
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 10.0)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
