//
//  ObservableObjectPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 8/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import XCTest

class ObservableObjectPublisherTests: XCTestCase {
    func testCodeExample() {
        let expectation = XCTestExpectation(description: debugDescription)
        class Contact: ObservableObject {
            @Published var name: String
            @Published var age: Int

            init(name: String, age: Int) {
                self.name = name
                self.age = age
            }

            func haveBirthday() -> Int {
                age += 1
                return age
            }
        }

        let john = Contact(name: "John Appleseed", age: 24)
        let cancellable = john.objectWillChange.sink { _ in
            expectation.fulfill()
            print("will change")
        }
        print(john.haveBirthday())
        // Prints "will change"
        // Prints "25"

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }

    class ExampleObject: ObservableObject {
        @Published var someProperty: String

        init(someProperty: String) {
            self.someProperty = someProperty
        }

        func shoutProperty() -> String {
            // this function is an example of something changing a published property
            someProperty = someProperty.uppercased()
            return someProperty
        }
    }

    func testObservableObjectPublisher() {
        let expectation = XCTestExpectation(description: debugDescription)

        let example = ExampleObject(someProperty: "quietly, please")

        XCTAssertNotNil(example.objectWillChange)
        let cancellable = example.objectWillChange
            .print("cancellable")
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                switch completion {
                case .finished:
                    XCTFail("No finished should be received from empty")
                case let .failure(anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                }
            }, receiveValue: { valueReceived in
                XCTAssertNotNil(valueReceived)
                // `valueReceived` is of type ObservableObject.Output, which is type-aliased in Foundation to Void...
                // so while it's not "nil", it'll never have any sort of real value  - it's just a token
                // to trigger the pipeline and should generally be taken in as an ignored value.
                expectation.fulfill()
                print(".sink() data received \(valueReceived)")
            })

        XCTAssertEqual(example.someProperty, "quietly, please")
        let result = example.shoutProperty()
        XCTAssertEqual(result, "QUIETLY, PLEASE")

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
    }
}
