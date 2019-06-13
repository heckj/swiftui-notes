# Description of Combine

Combine is a unified declarative framework for processing values over time. It is Apple's framework that
is built using the functional reactive concepts that can be found in other languages. If you are already familar
with ReactiveX extensions, there is [a pretty good cheat-sheet for translating the specifics between Rx and Combine](https://medium.com/gett-engineering/rxswift-to-apples-combine-cheat-sheet-e9ce32b14c5b),
built and inspired by the data collected at
[https://github.com/freak4pc/rxswift-to-combine-cheatsheet](https://github.com/freak4pc/rxswift-to-combine-cheatsheet).

Combine is Apple's functional reactive library. In Apple's words, it provides "a declarative Swift API
for processing values over time".

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

Operators are used to transform types - both the Output and Failure type. Operators may also split/duplicate streams, or merge streams, but must always be aligned by the combination of Output/Failure types.

The interals of the system are all driven by the subscriber. Subscribers and Publishers communicate in a well
defined sequence:

- the subscriber is attached to a publisher: `.subscribe(Subscriber)`
- the publisher sends a subscription: `receive(subscription)`
- subscriber requests _N_ values: `request(_ : Demand)`
- publisher sends _N_ (or fewer) values: `receive(_ : Input)`
- publisher sends completion: `receive(completion:)`

Operators fit in between Publishers and Subscribers. They adopt the
[Publisher protocol](https://developer.apple.com/documentation/combine/publisher), subscribing to
one or more Publishers, and sending results to one (or more) Subscribers.

## Publishers

[Publisher](https://developer.apple.com/documentation/combine/publisher)
A publisher defines how values (and errors) are produced, and allows the registration of a subscriber.

NotificationCenter.default.publisher

## Subscribers

Assign (`Subscribers.Assign(object: exampleObject, keyPath: \.someProperty)`)

## Operators

functional transformations

- map
- compactMap
- prefix
- decode

list operations

- filter

error handling
thread or queue movement
scheduling and time

combining streams
- zip
- combineLatest

flatMap
merge
reduce
contains
drop
collect

catch
dropFirst
allSatisfy
breakpoint
setFailureType
prepend
replaceError
append
filter
removeDuplicates
replaceNil
count
abortOnError
breakpointOnError
ignoreOutput
switchToLatest
scan
handleEvents
max
retry
first
log
mapError
print
min
last
output
replaceEmpty

The naming pattern of operators tends to follow similiar patterns on ordered collection types.

.assign (operator? subscriber?)