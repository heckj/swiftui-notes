//
//  MergeManyPublisherTests.swift
//  UsingCombineTests
//
//  Created by Евгений Орехин on 21.03.2021.
//  Copyright © 2021 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

final class MergeManyPublisherTests: XCTestCase {
    private let maxDelay: TimeInterval = 10.0

    /// Return the asyncronus publisher that send delay time as output after this delay
    private func createDelayedAsyncPublisher(minDelay: TimeInterval = 1.0) -> AnyPublisher<TimeInterval, Never> {
        let pub = Deferred {
            Future<TimeInterval, Never> { promise in
                let delay = TimeInterval(Int.random(in: Int(minDelay) ... Int(self.maxDelay)))
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    promise(.success(delay))
                }
            }
        }
        return pub.eraseToAnyPublisher()
    }

    func testMergeManyAsyncPublishersWithSyncronizedTerminating() {
        let expectation = XCTestExpectation(description: debugDescription)

        var output: [TimeInterval] = []

        var delayedAsyncPublishers = (0 ..< 5).map { _ in
            self.createDelayedAsyncPublisher()
        }

        delayedAsyncPublishers.append(createDelayedAsyncPublisher(minDelay: maxDelay))

        let mergedPublishers = Publishers.MergeMany(delayedAsyncPublishers)

        let cancellable = mergedPublishers
            .collect()
            .sink(receiveValue: { value in
                output = value
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: maxDelay)

        XCTAssertEqual(output.count,
                       6,
                       "The output count must be equal to 6 because of using collect operator and waiting output as long as max time interval delay")

        XCTAssertTrue(output.max() ?? 0 == maxDelay,
                      "The max value of output must be equal to the maximum delay of async operation \(maxDelay)")

        XCTAssertNotNil(cancellable)
    }
}
