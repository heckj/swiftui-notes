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
        // checks the validiry of a timestamp - this one should return {"valid":true}

        //validate
        let _ = URLSession.shared.dataTaskPublisher(for: sampleURL!)
            .subscribe(on: myBackgroundQueue)
            .map { $0.data }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .map { $0.valid }
            .eraseToAnyPublisher()
            .replaceError(with: false)
            .receive(on: RunLoop.main)
            .assign(to: \.boolValue, on: canary)

        wait(for: [sut], timeout: 5)
    }
}
