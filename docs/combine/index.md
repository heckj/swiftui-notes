# Description of Combine

Combine is a unified declarative framework for processing values over time. It is Apple's framework that
is built using the functional reactive concepts that can be found in other languages. If you are already familar
with ReactiveX extensions, there is [a pretty good cheat-sheet for translating the specifics between Rx and Combine](https://medium.com/gett-engineering/rxswift-to-apples-combine-cheat-sheet-e9ce32b14c5b), built and inspired by
the data collected at [https://github.com/freak4pc/rxswift-to-combine-cheatsheet](https://github.com/freak4pc/rxswift-to-combine-cheatsheet).

Combine is Apple's functional reactive library. In Apple's words, it provides "a declarative Swift API
for processing values over time".

## Core Concepts

Combine is built to process streams of events - one or more events, over time. It does so by sourcing data from **publishers**, transforming the events through **operators**, which are consumed by **subscribers**. These sequences, often called "streams" are composed and typically chained together.

Publisher and Subscriber are defined as protocols in Swift, and when defined in code are set up with two associated types: an Output type and a Failure type. Subscribers have an Input and Failure type defined, and these must align to the publisher types for the two to be composed together.

```
Publisher <OutputType>, <FailureType>
              |  |          |  |
               \/            \/
Subscriber <InputType>, <FailureType>
```

Operators are used to transform types - both the Output and Failure type. Operators may also split/duplicate streams, or merge streams, but must always be aligned by the combination of Output/Failure types.

### Publishers

A publisher defines how values (and errors) are produced, and allows the registration of a subscriber.

### Subscribers

### Operators