// Created by Ole Begemann
// https://gist.github.com/ole/efe13925abd8e8ea2c7926e9a3131abf

import XCTest

/// An expectation that is fulfilled when a Key Value Observing (KVO) condition
/// is met. It's a variant of `XCTKVOExpectation` with support for native Swift
/// key paths.
final class KVOExpectation: XCTestExpectation {
    private var kvoToken: NSKeyValueObservation?

    /// Creates an expectation that is fulfilled when a KVO change causes the
    /// specified key path of the observed object to have an expected value.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter expectedValue: The expected value for the observed key path.
    ///
    /// This initializer sets up KVO observation for keyPath with the
    /// `NSKeyValueObservingOptions.initial` option set. This means that the
    /// observed key path will be checked immediately after initialization.
    convenience init<Object: NSObject, Value: Equatable>(
        object objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        expectedValue: Value, file _: StaticString = #file, line _: Int = #line
    ) {
        self.init(object: objectToObserve, keyPath: keyPath, options: .initial) { obj, _ -> Bool in
            obj[keyPath: keyPath] == expectedValue
        }
    }

    /// Creates an expectation that is fulfilled by a KVO change for which the
    /// provided handler returns `true`.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter options: KVO options to be used for the observation.
    ///   The default value is `[]`.
    /// - Parameter handler: An optional handler block that will be invoked for
    ///   every KVO event. Return `true` to signal that the expectation should
    ///   be fulfilled. If you pass `nil` (the default value), the expectation
    ///   will be fulfilled by the first KVO event.
    ///
    /// When changes to the value are detected, the handler block is called to
    /// assess the new value to see if the expectation has been fulfilled. Every
    /// KVO event will run the handler block until it either returns `true` (to
    /// fulfill the expectation), or the wait times out.
    init<Object: NSObject, Value>(
        object objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [],
        file: StaticString = #file, line: Int = #line,
        handler: ((Object, NSKeyValueObservedChange<Value>) -> Bool)? = nil
    ) {
        super.init(description: KVOExpectation.description(forObject: objectToObserve, keyPath: keyPath, file: file, line: line))
        kvoToken = objectToObserve.observe(keyPath, options: options) { object, change in
            let isFulfilled = handler == nil || handler?(object, change) == true
            if isFulfilled {
                self.kvoToken = nil
                self.fulfill()
            }
        }
    }

    fileprivate static func description<Object: NSObject, Value>(forObject object: Object, keyPath: KeyPath<Object, Value>, file: StaticString, line: Int) -> String {
        return "\(file):\(line) – KVO expectation – object: \(object) – keyPath: \(keyPath)"
    }
}

extension XCTestCase {
    /// Creates an expectation that is fulfilled when a KVO change causes the
    /// specified key path of the observed object to have an expected value.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter expectedValue: The expected value for the observed key path.
    ///
    /// This initializer sets up KVO observation for keyPath with the
    /// `NSKeyValueObservingOptions.initial` option set. This means that the
    /// observed key path will be checked immediately after initialization.
    @discardableResult
    func keyValueObservingExpectation<Object: NSObject, Value: Equatable>(
        for objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        expectedValue: Value, file _: StaticString = #file, line _: Int = #line
    )
        -> XCTestExpectation
    {
        return keyValueObservingExpectation(for: objectToObserve, keyPath: keyPath, options: [.initial]) { obj, _ -> Bool in
            obj[keyPath: keyPath] == expectedValue
        }
    }

    /// Creates an expectation that is fulfilled by a KVO change for which the
    /// provided handler returns `true`.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter options: KVO options to be used for the observation.
    ///   The default value is `[]`.
    /// - Parameter handler: An optional handler block that will be invoked for
    ///   every KVO event. Return `true` to signal that the expectation should
    ///   be fulfilled. If you pass `nil` (the default value), the expectation
    ///   will be fulfilled by the first KVO event.
    ///
    /// When changes to the value are detected, the handler block is called to
    /// assess the new value to see if the expectation has been fulfilled. Every
    /// KVO event will run the handler block until it either returns `true` (to
    /// fulfill the expectation), or the wait times out.
    @discardableResult
    func keyValueObservingExpectation<Object: NSObject, Value>(
        for objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [],
        file: StaticString = #file, line: Int = #line,
        handler: ((Object, NSKeyValueObservedChange<Value>) -> Bool)? = nil
    )
        -> XCTestExpectation
    {
        let wrapper = expectation(description: KVOExpectation.description(forObject: objectToObserve, keyPath: keyPath, file: file, line: line))
        // Following XCTest precedent, which sets `assertForOverFulfill` to true by default
        // for expectations created with `XCTestCase` convenience methods.
        wrapper.assertForOverFulfill = true
        // The KVO handler inside KVOExpectation retains its parent object while the observation is active.
        // That's why we can get away with not retaining the KVOExpectation here.
        _ = KVOExpectation(object: objectToObserve, keyPath: keyPath, options: options) { object, change in
            let isFulfilled = handler == nil || handler?(object, change) == true
            if isFulfilled {
                wrapper.fulfill()
                return true
            } else {
                return false
            }
        }
        return wrapper
    }
}

class KVOExpectationTests: XCTestCase {
    func test_settingProperty_fulfillsExpectation() {
        let kvoObject = KVOAbleNSObject()
        let sut = KVOExpectation(object: kvoObject, keyPath: \.intValue) { obj, _ -> Bool in
            obj.intValue == 10
        }
        kvoObject.intValue = 10
        wait(for: [sut], timeout: 1)
    }

    func test_doesNotFulfill_unlessPredicateIsTrue() {
        let kvoObject = KVOAbleNSObject()
        let first = KVOExpectation(object: kvoObject, keyPath: \.intValue) { obj, _ -> Bool in
            obj.intValue == 20
        }
        first.isInverted = true
        let second = KVOExpectation(object: kvoObject, keyPath: \.intValue) { obj, _ -> Bool in
            obj.intValue == 20
        }
        kvoObject.intValue = 10
        wait(for: [first], timeout: 1)
        kvoObject.intValue = 20
        wait(for: [second], timeout: 1)
    }

    func test_fulfillingWithInitialValue_requiresInitialKVOOption() {
        let kvoTarget = KVOAbleNSObject()
        kvoTarget.intValue = 10
        let expectWithoutInitial = KVOExpectation(object: kvoTarget, keyPath: \.intValue, options: []) { obj, _ -> Bool in
            obj.intValue == 10
        }
        expectWithoutInitial.isInverted = true
        let expectWithInitial = KVOExpectation(object: kvoTarget, keyPath: \.intValue, options: .initial) { obj, _ -> Bool in
            obj.intValue == 10
        }
        wait(for: [expectWithoutInitial, expectWithInitial], timeout: 1)
    }

    func test_nilHandler_fulfillsOnFirstKVOEvent() {
        let kvoObject = KVOAbleNSObject()
        let sut = KVOExpectation(object: kvoObject, keyPath: \.intValue)
        kvoObject.intValue = 30
        wait(for: [sut], timeout: 1)
    }

    func test_comparesAgainstExpectedValue() {
        let kvoObject = KVOAbleNSObject()
        let first = KVOExpectation(object: kvoObject, keyPath: \.intValue, expectedValue: 20)
        first.isInverted = true
        let second = KVOExpectation(object: kvoObject, keyPath: \.intValue, expectedValue: 20)
        kvoObject.intValue = 10
        wait(for: [first], timeout: 1)
        kvoObject.intValue = 20
        wait(for: [second], timeout: 1)
    }

    func test_expectedValueIsComparedImmediatelyOnInit() {
        let kvoObject = KVOAbleNSObject()
        kvoObject.intValue = 10
        let sut = KVOExpectation(object: kvoObject, keyPath: \.intValue, expectedValue: 10)
        wait(for: [sut], timeout: 1)
    }

    func test_fulfillsExpectationJustOnce() {
        let kvoObject = KVOAbleNSObject()
        let sut = KVOExpectation(object: kvoObject, keyPath: \.intValue)
        sut.expectedFulfillmentCount = 1
        sut.assertForOverFulfill = true
        kvoObject.intValue = 10
        kvoObject.intValue = 20
        kvoObject.intValue = 30
        wait(for: [sut], timeout: 1)
    }

    func test_supportsXCTestCaseConvenienceAPI() {
        let kvoObject = KVOAbleNSObject()
        keyValueObservingExpectation(for: kvoObject, keyPath: \.intValue) { obj, _ in
            obj.intValue == 10
        }
        kvoObject.intValue = 10
        waitForExpectations(timeout: 1)
    }

    func test_XCTestCaseConvenienceAPI_onlyFiresWhenPredicateIsTrue() {
        let kvoObject = KVOAbleNSObject()
        let sut = keyValueObservingExpectation(for: kvoObject, keyPath: \.intValue) { obj, _ in
            obj.intValue == 20
        }
        sut.isInverted = true
        kvoObject.intValue = 10
        waitForExpectations(timeout: 1)
    }

    func test_supportsXCTestCaseConvenienceAPIWithExpectedValue() {
        let kvoObject = KVOAbleNSObject()
        let first = keyValueObservingExpectation(for: kvoObject, keyPath: \.intValue, expectedValue: 20)
        first.isInverted = true
        kvoObject.intValue = 10
        waitForExpectations(timeout: 1)
        keyValueObservingExpectation(for: kvoObject, keyPath: \.intValue, expectedValue: 20)
        kvoObject.intValue = 20
        waitForExpectations(timeout: 1)
    }
}

private final class KVOAbleNSObject: NSObject {
    @objc dynamic var intValue: Int = 0
}

// KVOExpectationTests.defaultTestSuite.run()
