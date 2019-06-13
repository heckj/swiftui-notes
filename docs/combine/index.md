# Description of Combine

Combine is a unified declarative framework for processing values over time. It is Apple's
framework that is built using the functional reactive concepts that can be found in other
languages. If you are already familar with ReactiveX extensions, there is [a pretty good cheat-sheet for translating the specifics between Rx and Combine](https://medium.com/gett-engineering/rxswift-to-apples-combine-cheat-sheet-e9ce32b14c5b),
built and inspired by the data collected at
[https://github.com/freak4pc/rxswift-to-combine-cheatsheet](https://github.com/freak4pc/rxswift-to-combine-cheatsheet).

Combine is Apple's functional reactive library. In Apple's words, it provides
> "a declarative Swift API for processing values over time".

## Core Concepts

Combine is built to process streams of events - one or more events, over time. It does so by
sourcing data from **publishers**, transforming the events through **operators**, which are
consumed by **subscribers**. These sequences, often called "streams" are composed and typically
chained together.

[Publisher](https://developer.apple.com/documentation/combine/publisher) and
[Subscriber](https://developer.apple.com/documentation/combine/subscriber) are defined as
protocols in Swift, and when defined in code are set up
with two associated types: an Output type and a Failure type. Subscribers have an Input and Failure
type defined, and these must align to the publisher types for the two to be composed together.

```
Publisher <OutputType>, <FailureType>
              |  |          |  |
               \/            \/
Subscriber <InputType>, <FailureType>
```

Operators are used to transform types - both the Output and Failure type. Operators may also
split or duplicate streams, or merge streams, Operators must always be aligned by the combination
of Output/Failure types.

The interals of the system are all driven by the subscriber. Subscribers and Publishers
communicate in a well defined sequence:

- the subscriber is attached to a publisher: `.subscribe(Subscriber)`
- the publisher sends a subscription: `receive(subscription)`
- subscriber requests _N_ values: `request(_ : Demand)`
- publisher sends _N_ (or fewer) values: `receive(_ : Input)`
- publisher sends completion: `receive(completion:)`

Operators fit in between Publishers and Subscribers. They adopt the
[Publisher protocol](https://developer.apple.com/documentation/combine/publisher), subscribing
to one or more Publishers, and sending results to one (or more) Subscribers.

## Publishers

[Publisher](https://developer.apple.com/documentation/combine/publisher)
A publisher defines how values (and errors) are produced, and allows the registration of a subscriber.

NotificationCenter.default.publisher -> <Notification>, <Never>

Just -> <SomeType>, <Never>

- often used in error handling, provides a single result as a stream and ends

publisher -> <SomeType>, <Never>

- extracts a property from an object and returns it
- ex: `.publisher(for: \.name)`

BindableObject

- often linked with method `didChange` to publish changes to model objects
- `@ObjectBinding var model: MyModel`

@Published

- property wrapper that adds a Combine publisher to any property

Future

- you provide a closure that converts a callback/function of your own choosing into a promise.
- example:

```swift
return Future { promise in
  self.myFunctionCall(someVariable) { varname in
    promise(.success(varname ? username : nil))
  }
}
```

- can be used within a Flatmap in an operator sequence to do your own processing/logic within
  a stream, call out to an external service, etc.
- commonly used when making external service calls over the network.


## Subscribers

Cancellation:

Subscribers can support cancellation, which terminates a subscription early.

```swift
let trickNamePublisher = ... // Publisher of <String, Never>

let canceller = trickNamePublisher.sink { trickName in
}
```

Kinds of subscribers:

- key-path assignment
  - ex: `Subscribers.Assign(object: exampleObject, keyPath: \.someProperty)`
  - ex: `.assign(to: \.isEnabled, on: signupButton)`

- Sink
  - you provide a closure where you process the results

- Subject
  - behave like both a publisher and subscriber
  - broadcasts values to multiple subscribers
  - `Passthrough` and `CurrentValue` subscribers
    - Passthrough doesn't maintain any state - just passes through provided values
    - CurrentValue remembers the current value so that when you attach a subscriber you can see the current value

- SwiftUI
  - SwiftUI provides the subscribers, you primarily fill in the publishers and operators

## Operators


The naming pattern of operators tends to follow similiar patterns on ordered collection types.

signature transformations

- eraseToAnyPublisher
  - when you chain operators together in swift, the object's type signature accumulates all the various
    types, and it gets ugly pretty quickly.
  - eraseToAnyPublisher takes the signature and "erases" the type back to the common type of AnyPublisher
  - this provides a cleaner type for external declarations (framework was created prior to Swift 5's opaque types)
  - `.eraseToAnyPublisher()`
  - often at the end of chains of operators, and cleans up the type signature of the property getting asigned to the chain of operators

functional transformations

- map
  - you provide a closure that gets the values and chooses what to publish

- compactMap
  - you provide a closure that gets the values and chooses what to publish

- prefix
- decode
  - common operating where you hand in a type of decoder, and transform data (ex: JSON) into an object
  - can fail, so it returns an error type
  -> <SomeType>, <Error>

- flatMap
  - collapses nil values out of a stream
  - used with error recovery or async operations that might fail (ex: Future)

- removeDuplicates
  - `.removeDuplicates()`
  - remembers what was previously sent in the stream, and only passes forward new values

list operations

- filter
- merge
- reduce
- contains
- drop
- dropFirst
- last
- count

error handling

- assertNoFailure
- retry
- catch
- mapError
- setFailureType

- breakpoint

thread or queue movement

- receive(on:)
  `.receive(on: RunLoop.main)`

- subscribe(on:)

scheduling and time

- throttle
- delay
- debounce
  - `.debounce(for: 0.5, scheduler: RunLoop.main)`
  - collapses multiple values within a specified time window into a single value
  - often used with `.removeDuplicates()`

combining streams

- zip
- combineLatest
  - brings inputs from 2 (or more) streams together
  - you provide a closure that gets the values and chooses what to publish

(operators to be organized and described):

- collect
- max
- min

- allSatisfy
- prepend
- replaceError
- append
- filter
- replaceNil
- abortOnError
- breakpointOnError
- ignoreOutput
- switchToLatest
- scan
- handleEvents
- first
- log
- print
- output
- replaceEmpty

