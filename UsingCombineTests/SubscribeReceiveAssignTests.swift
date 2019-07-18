//
//  SubscribeReceiveAssignTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/5/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class SubscribeReceiveAssignTests: XCTestCase {

    private final class KVOAbleNSObject: NSObject {
        @objc dynamic var intValue: Int = 0
        @objc dynamic var boolValue: Bool = false
    }

    fileprivate struct PostmanEchoTimeStampCheckResponse: Decodable, Hashable {
        let valid: Bool
    }

    func testSubscribeReceiveAssignPipeline() {
        // setup
        let canary = KVOAbleNSObject()
        let myBackgroundQueue = DispatchQueue(label: "UsingCombineExample", attributes: .concurrent)
        let sut = KVOExpectation(object: canary, keyPath: \.boolValue) { (obj, change) -> Bool in
            return obj.boolValue
        }
        let sampleURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")
        // checks the validity of a timestamp - this one should return {"valid":true}

        //validate
        let cancellable = URLSession.shared.dataTaskPublisher(for: sampleURL!)
            .subscribe(on: myBackgroundQueue)
            .map { $0.data }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .map { $0.valid }
            .eraseToAnyPublisher()
            .replaceError(with: false)
            .receive(on: RunLoop.main)
            .assign(to: \.boolValue, on: canary)

        wait(for: [sut], timeout: 5)
        XCTAssertNotNil(cancellable)
    }
  
  func testJustSubscribeOnReceiveOn() {
    // setup
    let upstreamName = "upstream"
    let upstreamScheduler = DispatchQueue(label: upstreamName)

    let downstreamName = "downstream"
    let downstreamScheduler = DispatchQueue(label: downstreamName)
    
    var upstreamResult: String?
    var downstreamResult: String?
    let exp = self.expectation(description: #function)

    // validate
    let cancellable = Just<Void>(())
      .subscribe(on: upstreamScheduler)
      .map({ _ in
        let name = __dispatch_queue_get_label(nil)
        upstreamResult = String(cString: name, encoding: .utf8)
      })
      .receive(on: downstreamScheduler)
      .sink(receiveValue: { _ in
        let name = __dispatch_queue_get_label(nil)
        downstreamResult = String(cString: name, encoding: .utf8)
        exp.fulfill()
    })
    
    waitForExpectations(timeout: 1)
    XCTAssertEqual(upstreamName, upstreamResult ?? nil)
    XCTAssertEqual(downstreamName, downstreamResult ?? nil)
    XCTAssertNotNil(cancellable)
  }

    func testMixedQueuesSubscribeReceiveDelayPipeline() {

        // setup
        let simplePublisher = PassthroughSubject<String, Never>()
        let expectation = XCTestExpectation(description: self.debugDescription)

        let firstQueue = DispatchQueue(label: "firstQueue")
        let secondQueue = DispatchQueue(label: "secondQueue")
        let thirdQueue = DispatchQueue(label: "thirdQueue")
        let sendQueue = DispatchQueue(label: "sendQueue")
        // checks the validity of a timestamp - this one should return {"valid":true}

        //validate
        let cancellable = simplePublisher
            .map { someValue -> String in
                print("map after publisher on queue:", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                // NOTE(heckj): I expected this would be modified by the subscribe operator following, but it remains on the queue
                // from which the send originated (sendQueue in this case)
                // XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "firstQueue")
                return someValue
            }
            .subscribe(on: firstQueue) // should impact this and previous operators
            .map { someValue -> String in
                print("map after subscribe on queue:", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                // NOTE(heckj): I expected this would *also* be modified by the subscribe operator, leaving all following operators on
                // the same queue, however it it remains on the queue from which the publisher originated (sendQueue in this case)
                // XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "firstQueue")
                return someValue
            }
            .delay(for: 1.0, scheduler: secondQueue)
            .map { someValue -> String in
                print("map after delay on queue:", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                // delay changes the queue for following operations
                XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "secondQueue")
                return someValue
            }
            .throttle(for: 1.0, scheduler: thirdQueue, latest: true)
            .map { someValue -> String in
                // throttle changes the queue for following operations as well
                print("map after throttle on queue:", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "thirdQueue")
                return someValue
            }
            .receive(on: RunLoop.main)
            .sink { _ in
                // explicitly shifting to the main thread from the receive operator
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "com.apple.main-thread")
                expectation.fulfill()
            }

        XCTAssertNotNil(cancellable)
        sendQueue.asyncAfter(deadline: .now() + 0.1, execute: {
            print("sending data on queue:", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
            simplePublisher.send("something in")
        })

        wait(for: [expectation], timeout: 5)
    }

    func testSubscribeAndDataTaskQueueHandling() {

        // setup
        let expectation = XCTestExpectation(description: self.debugDescription)

        let firstQueue = DispatchQueue(label: "firstQueue")
        let sampleURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")
        // checks the validity of a timestamp - this one should return {"valid":true}

        //validate
        let cancellable = URLSession.shared.dataTaskPublisher(for: sampleURL!)
            .map {
                print("map after dataTask on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                // XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "firstQueue")
                return $0.data
            }
            .subscribe(on: firstQueue)
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .map {
                print("map after decode on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                // XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "firstQueue")
                return $0.valid
            }
            .eraseToAnyPublisher()
            .replaceError(with: false)
            .receive(on: RunLoop.main)
            .sink { _ in
                // explicitly shifting to the main thread from the receive operator
                print("sink invoked on queue label ", String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!)
                XCTAssertEqual(String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)!, "com.apple.main-thread")
                expectation.fulfill()
            }

        // checks the validity of a timestamp - this one should return {"valid":true}
        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5)
    }
}
