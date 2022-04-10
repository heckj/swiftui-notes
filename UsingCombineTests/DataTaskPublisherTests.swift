//
//  DataTaskPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/5/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class DataTaskPublisherTests: XCTestCase {
    var testURL: URL?
    var mockURL: URL?
    var myBackgroundQueue: DispatchQueue?

    enum TestFailureCondition: Error {
        case invalidServerResponse
    }

    // heroku app that returns errors: https://github.com/heckj/barkshin
    let test404UrlString = "https://barkshin.herokuapp.com/missing"
    let test400UrlString = "https://barkshin.herokuapp.com/badRequest"
    let test500UrlString = "https://barkshin.herokuapp.com/generalError"

    let testUrlString = "https://postman-echo.com/time/valid?timestamp=2016-10-10"
    // checks the validity of a timestamp - this one should return {"valid":true}
    // matching the data structure returned from https://postman-echo.com/time/valid
    fileprivate struct PostmanEchoTimeStampCheckResponse: Decodable, Hashable {
        let valid: Bool
    }

    override func setUp() {
        testURL = URL(string: testUrlString)
        myBackgroundQueue = DispatchQueue(label: "UsingCombineExample")
        // Apple recommends NOT using .concurrent queue when working with Combine pipelines:
        // https://forums.swift.org/t/runloop-main-or-dispatchqueue-main-when-using-combine-scheduler/26635/4
        mockURL = URL(string: "https://fakeurl.com/response")
        // ignore the testURL and let it pass through and do its thing
        Mocker.ignore(testURL!)
        Mocker.ignore(URL(string: test400UrlString)!)
        Mocker.ignore(URL(string: test404UrlString)!)
        Mocker.ignore(URL(string: test500UrlString)!)
    }

    func testDataTaskPublisher() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: testURL!)
            // validate
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion", String(describing: fini))
                switch fini {
                case .finished: expectation.fulfill()
                case .failure: XCTFail()
                }
            }, receiveValue: { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Unable to parse response an HTTPURLResponse")
                    return
                }
                XCTAssertNotNil(data)
                // print(".sink() data received \(data)")
                XCTAssertNotNil(httpResponse)
                XCTAssertEqual(httpResponse.statusCode, 200)
                // print(".sink() httpResponse received \(httpResponse)")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)
    }

    func testSimpleURLDecodePipeline() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: testURL!)
            // the dataTaskPublisher output combination is (data: Data, response: URLResponse)
            .map { $0.data }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: myBackgroundQueue!)
            .eraseToAnyPublisher()

        XCTAssertNotNil(remoteDataPublisher)

        // validate
        let cancellable = remoteDataPublisher
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished: expectation.fulfill()
                case .failure: XCTFail()
                }
            }, receiveValue: { someValue in
                XCTAssertNotNil(someValue)
                print(".sink() received \(someValue)")
            })

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    func testSimpleFailingURLDecodePipeline_URLError() {
        // setup
        let myURL = URL(string: "https://doesntexist.jsontest.com") // whole chain fails with completion/error sent from dataTaskPublisher
        let expectation = XCTestExpectation(description: "Download from \(String(describing: myURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: myURL!)
            // the dataTaskPublisher output combination is (data: Data, response: URLResponse)
            .map { $0.data }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: myBackgroundQueue!)
            .eraseToAnyPublisher()

            // validate
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion", String(describing: fini))
                switch fini {
                case .finished: XCTFail()
                case let .failure(anError):
                    print("received error: ", anError)
                    // URL doesn't exist, so a failure should be triggered
                    // normally, the error description would be "A server with the specified hostname could not be found."
                    // but our mocking system screws with the errors
                    // XCTAssertEqual(anError.localizedDescription, "A server with the specified hostname could not be found.")
                    expectation.fulfill()
                }
            }, receiveValue: { someValue in
//                XCTAssertNotNil(someValue)
                XCTFail("Should not have received a value with the failed URL")
                print(".sink() received \(someValue)")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)
    }

    func testDataTaskPublisherWithTryMap() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: testURL!)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw TestFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: myBackgroundQueue!)
            .eraseToAnyPublisher()

            // validate
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: expectation.fulfill()
                case let .failure(anError):
                    XCTFail(anError.localizedDescription)
                }
            }, receiveValue: { decodedResponse in
                XCTAssertNotNil(decodedResponse)
                XCTAssertTrue(decodedResponse.valid)
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)
    }

    func testDataTaskPublisherWithDelayedRetry() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        var countOfMockURLRequests = 0

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        var m = Mock(url: mockURL!, ignoreQuery: false, reportFailure: true, dataType: .json, statusCode: 500,
                     data: [.get: Data()])
        m.delay = DispatchTimeInterval.milliseconds(500)
        m.completion = {
            countOfMockURLRequests += 1
            print("MOCK URL COMPLETION CALLED", Date())
        }
        m.register()

        guard let backgroundQueue = myBackgroundQueue else {
            XCTFail()
            return
        }

        let remoteDataPublisher = urlSession.dataTaskPublisher(for: mockURL!)
            .delay(for: DispatchQueue.SchedulerTimeType.Stride(integerLiteral: Int.random(in: 1 ..< 5)), scheduler: backgroundQueue)
            .retry(3)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw TestFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: backgroundQueue)
            .eraseToAnyPublisher()

            // validate
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Finished without failure report")
                    XCTFail("Should have failed, not completed")
                case let .failure(anError):
                    print("Received error from failure completion: ", anError.localizedDescription)
                }
                expectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("No data is expected to be received")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 30.0)
        XCTAssertEqual(countOfMockURLRequests, 4)
    }

    func testDataTaskPublisherWithDelayedRetryAndTimeout() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")
        var countOfMockURLRequests = 0

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        var m = Mock(url: mockURL!, ignoreQuery: false, reportFailure: true, dataType: .json,
                     statusCode: 500,
                     data: [.get: Data()])
        m.delay = DispatchTimeInterval.milliseconds(500)

        m.completion = {
            countOfMockURLRequests += 1
            print("MOCK URL COMPLETION CALLED", Date())
        }
        m.register()

        guard let backgroundQueue = myBackgroundQueue else {
            XCTFail()
            return
        }

        let remoteDataPublisher = urlSession.dataTaskPublisher(for: mockURL!)
            .delay(for: 2, scheduler: backgroundQueue)
            .retry(5) // 5 retries, 2 seconds each ~ 10 seconds for this to fall through
            .timeout(5, scheduler: backgroundQueue) // max time of 5 seconds before failing
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw TestFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: backgroundQueue)
            .eraseToAnyPublisher()

            // validate
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case let .failure(anError):
                    print("Received error from failure completion: ", anError.localizedDescription)
                    XCTFail("Should have finished, not failed, with a timeout")
                }
                expectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("No data is expected to be received")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 30.0)
        // with a timeout of 5 seconds, and a 2 second delay, the retries should have only happened twice before
        // the timeout triggered.
        XCTAssertEqual(countOfMockURLRequests, 2)
    }

    func testDataTaskPublisherWithTryMapAndFlatMap() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: testURL))")

        let remoteDataPublisher = Just(testURL!)
            .flatMap { url in
                URLSession.shared.dataTaskPublisher(for: url)
                    .tryMap { data, response -> Data in
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200
                        else {
                            throw TestFailureCondition.invalidServerResponse
                        }
                        return data
                    }
                    .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
                    .catch { _ in
                        Just(PostmanEchoTimeStampCheckResponse(valid: false))
                    }
            }
            .subscribe(on: myBackgroundQueue!)
            .eraseToAnyPublisher()
            // validate
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: expectation.fulfill()
                case let .failure(anError):
                    XCTFail(anError.localizedDescription)
                }
            }, receiveValue: { decodedResponse in
                XCTAssertNotNil(decodedResponse)
                XCTAssertTrue(decodedResponse.valid)
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - tests working against a site that produces explicit failures

    /// Test specifically to see how dataTaskPublisher handles an HTTP response wiht a 400 response code. The code it's testing is hosted on Heroku on a free instance,
    /// so I'm disabling this test to not abuse that service, and because the first time it's run it frequently fails (as the instance spins up from the first request).
    /// The code that provides this endpoint is available at Github: https://github.com/heckj/barkshin.
    func SKIP_testDataTaskPublisherFailure400URL() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: test400UrlString))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: test400UrlString)!)
            // validate
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion", String(describing: fini))
                switch fini {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Unable to parse response an HTTPURLResponse")
                    return
                }
                let stringedData = String(data: data, encoding: .utf8)
                print(".sink() data received \(data) as \(String(describing: stringedData))")
                print(".sink() httpResponse received \(httpResponse)")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)

        /*

         .sink() data received 12 bytes as Optional("bad request!")
         .sink() httpResponse received <NSHTTPURLResponse: 0x6000019351c0> { URL: https://barkshin.herokuapp.com/badRequest } { Status Code: 400, Headers {
         Connection =     (
         "keep-alive"
         );
         "Content-Length" =     (
         12
         );
         "Content-Type" =     (
         "text/html; charset=utf-8"
         );
         Date =     (
         "Sun, 07 Jul 2019 00:45:18 GMT"
         );
         Server =     (
         "gunicorn/19.9.0"
         );
         Via =     (
         "1.1 vegur"
         );
         } }
         .sink() received the completion finished

         */
    }

    /// Test specifically to see how dataTaskPublisher handles an HTTP response wiht a 400 response code. The code it's testing is hosted on Heroku on a free instance,
    /// so I'm disabling this test to not abuse that service, and because the first time it's run it frequently fails (as the instance spins up from the first request).
    /// The code that provides this endpoint is available at Github: https://github.com/heckj/barkshin.
    func SKIP_testDataTaskPublisherFailure404URL() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: test404UrlString))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: test404UrlString)!)
            // validate
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion", String(describing: fini))
                switch fini {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Unable to parse response an HTTPURLResponse")
                    return
                }
                let stringedData = String(data: data, encoding: .utf8)
                print(".sink() data received \(data) as \(String(describing: stringedData))")

                print(".sink() httpResponse received \(httpResponse)")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)

        /*

         .sink() data received 232 bytes as Optional("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n<title>404 Not Found</title>\n<h1>Not Found</h1>\n<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>\n")
         .sink() httpResponse received <NSHTTPURLResponse: 0x60000249bd40> { URL: https://barkshin.herokuapp.com/missing/ } { Status Code: 404, Headers {
         Connection =     (
         "keep-alive"
         );
         "Content-Length" =     (
         232
         );
         "Content-Type" =     (
         "text/html"
         );
         Date =     (
         "Sun, 07 Jul 2019 00:38:33 GMT"
         );
         Server =     (
         "gunicorn/19.9.0"
         );
         Via =     (
         "1.1 vegur"
         );
         } }
         .sink() received the completion finished

         */
    }

    /// Test specifically to see how dataTaskPublisher handles an HTTP response wiht a 400 response code. The code it's testing is hosted on Heroku on a free instance,
    /// so I'm disabling this test to not abuse that service, and because the first time it's run it frequently fails (as the instance spins up from the first request).
    /// The code that provides this endpoint is available at Github: https://github.com/heckj/barkshin.
    func SKIP_testDataTaskPublisherFailure500URL() {
        // setup
        let expectation = XCTestExpectation(description: "Download from \(String(describing: test500UrlString))")
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: test500UrlString)!)
            // validate
            .sink(receiveCompletion: { fini in
                print(".sink() received the completion", String(describing: fini))
                switch fini {
                case .finished:
                    break
                case let .failure(anError):
                    print("received error: ", anError)
                }
                expectation.fulfill()
            }, receiveValue: { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("Unable to parse response an HTTPURLResponse")
                    return
                }
                let stringedData = String(data: data, encoding: .utf8)
                print(".sink() data received \(data) as \(String(describing: stringedData))")
                print(".sink() httpResponse received \(httpResponse)")
            })

        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)

        /*

         .sink() data received 6 bytes as Optional("error!")
         .sink() httpResponse received <NSHTTPURLResponse: 0x600003d2ed20> { URL: https://barkshin.herokuapp.com/generalError } { Status Code: 500, Headers {
         Connection =     (
         "keep-alive"
         );
         "Content-Length" =     (
         6
         );
         "Content-Type" =     (
         "text/html; charset=utf-8"
         );
         Date =     (
         "Sun, 07 Jul 2019 00:42:04 GMT"
         );
         Server =     (
         "gunicorn/19.9.0"
         );
         Via =     (
         "1.1 vegur"
         );
         } }
         .sink() received the completion finished

         */
    }
}
