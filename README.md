# SwiftUI-Notes

A collection of notes, project pieces, playgrounds and ideas on learning and using SwiftUI and Combine.
Changes, corrections, and feedback all welcome! See [CONTRIBUTING](CONTRIBUTING.md) for details and links.

## Goal

I wanted to learn Combine, so describing how to use it to other people works really well for me.
My goal for this is to create easily accessible reference documentation for myself, and for anyone else
wanting to use it. I do (not-so-secretly) hope that Apple's own reference documentation will completely
obviate the reference section of all of this, but it doesn't today.

What makes good reference documentation for me:

- core concepts in some detail, explaining what's intended and expected
- reference of all of the classes and functions you might use, organized and grouped by why you might be using them
  - having commented sample code that illustrate how the function or class can be used
- common or frequent recipes/patterns of how you might want to use this framework
- how to test/validate your own creations using the framework

Bonus points:

- internal self-references to functions, classes, and concepts to supporting navigating based on what you're trying to learn or understand
  - self-consistent navigation of rendered content
- usable from mobile & desktop
- diagrams for the functions to make what they do more easily understood (aka marble diagrams)
- consumable in multiple formats: hosted HTML, pdf, epub
  - hosted HTML easily referencable from source code

## Where stuff resides

The [`docs` directory](https://github.com/heckj/swiftui-notes/tree/master/docs) in this
repository is the source for the HTML content hosted at https://heckj.github.io/swiftui-notes/

The project (`SwiftUI-Notes.xcodeproj`) has sample code, tests, and trials used in building and vetting
the content.

The content is hosted by Github (on github pages), generated with Jekyll, primarily written in Markdown.

### Setting up asciidoctor for local rendering

- get a more recent ruby (I'm using rbenv with `brew install rbenv`), current 2.6.3

```bash
rbenv install 2.6.3
rbenv global 2.6.3

gem install bundler
gem install asciidoctor
NOKOGIRI_USE_SYSTEM_LIBRARIES=1 gem install asciidoctor-epub3 --pre
gem install pygments.rb
```

### Rendering

```bash
cd docs
asciidoctor-epub3 -D output using-combine-book.adoc
asciidoctor-pdf -D output using-combine-book.adoc
asciidoctor -D html -r ./lib/google-analytics-docinfoprocessor.rb using-combine-book.adoc
```

A variation of these commands are included in the [`.travisCI`](.travis.yml) build configuration.

You can do all this rendering locally with docker. Do this from the **top** of the repository:

    # get the docker image loaded up
    docker pull asciidoctor/docker-asciidoctor

    # render the HTML, results should appear in `output` directory
    docker run --rm -v $(pwd):/documents/ --name asciidoc-to-html asciidoctor/docker-asciidoctor asciidoctor -D /documents/output -r ./docs/lib/google-analytics-docinfoprocessor.rb docs/using-combine-book.adoc

    # render a PDF, results should appear in `output` directory
    docker run --rm -v $(pwd):/documents/ --name asciidoc-to-pdf asciidoctor/docker-asciidoctor asciidoctor-pdf -D /documents/output docs/using-combine-book.adoc

    # render an epub3 file, results should appear in `output` directory
    docker run --rm -v $(pwd):/documents/ --name asciidoc-to-epub3 asciidoctor/docker-asciidoctor asciidoctor-epub3 -D /documents/output docs/using-combine-book.adoc

## Outline (work in progress)

- Combine

  - Introduction/what it is

  - Core Concepts
    - Publisher
    - Subscriber
    - Subject
    - Operators

  - Using Combine (aka patterns and recipes)

    - sequencing async operations
      - handling errors, fallback pattern

    - binding with models
    - binding with notifications
    - binding to SwiftUI
      - validating forms
      - UX responsiveness - live updates

  - Reference

    - Publishers
      - Just
      - Once
      - Optional
      - Sequence
      - Deferred
      - BindableObject (protocol)
      - Published (property wrapper)
      - DataTaskPublisher
      - Future

      - eraseToAnyPublisher

    - Subscribers
      - sink
      - assign

    - Subject
      - Passthrough
      - CurrentValue

      - eraseToAnySubject

    - Operators (functional)
      - map
      - compactMap
      - prefix
      - decode
      - encode
      - removeDuplicates

    - Operators (splitting/combining streams)
      - zip
      - combineLatest
      - flatMap
      - allSatisfy (tryAllSatisfy)
      - replaceError
      - replaceEmpty
      - replaceNil
      - ignoreOutput

    - Operators (list operations)
      - merge
      - reduce
      - dropFirst
      - count
      - comparison
      - prepend
      - append
      - max
      - min

    - Operators (conditional operations)
      - filter
      - first
      - last
      - contains
      - drop

    - Operators (error handling)
      - assertNoFailure
      - retry
      - catch
      - mapError
      - setFailureType

    - Operators (debugging)
      - breakpoint
      - breakpointOnError
      - abortOnError
      - log
      - print

    - Operators (thread/queue handling)
      - receive(on:)
      - subscribe(on:)

    - Operators (time handling)
      - throttle
      - timeout
      - debounce
      - delay
      - measureInterval
      - collect

    - Operators (unsure)
      - scan
      - handleEvents
      - multicast
      - output
