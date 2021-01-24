![Using Combine](https://raw.githubusercontent.com/heckj/swiftui-notes/master/Assets/Images/UsingCombineWithSwiftGitHubSocial.png)

# SwiftUI-Notes [![Build Status](https://travis-ci.org/heckj/swiftui-notes.svg?branch=master)](https://travis-ci.org/heckj/swiftui-notes)

A collection of notes, project pieces, playgrounds and ideas on learning and using SwiftUI and Combine.
Changes, corrections, and feedback all welcome! See [CONTRIBUTING](CONTRIBUTING.md) for details and links.

## Goal

While I started digging into SwiftUI, I was attracted to Combine and realized how much depth there was in just the Combine framework.
I wanted to learn Combine, and describing how to use it to other people works really well for me.

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
repository is the source for the HTML content hosted at <https://heckj.github.io/swiftui-notes/>

The project (`SwiftUI-Notes.xcodeproj`) has sample code, tests, and trials used in building and vetting
the content.

The content is hosted by Github (on github pages), generated with Jekyll, primarily written in Markdown.

### Setting up asciidoctor for local rendering

- get a more recent ruby (I'm using rbenv with `brew install rbenv`), current 2.6.3

The git metadata requires "rugged", which wants cmake to install it... so you might need to
`brew install cmake` to make this all work.

```bash
rbenv install 2.6.3
rbenv global 2.6.3

gem install bundler
gem install asciidoctor
NOKOGIRI_USE_SYSTEM_LIBRARIES=1 gem install asciidoctor-epub3 --pre
gem install pygments.rb

gem install rugged # required for the git-metadata extension, requires 'cmake'
```

If you have docker installed, you can also use a docker image to do the rendering,
and not have to install anything directly. If you want to try out different extensions,
you probably want to install this locally, but if you're just generating the output
then the docker path is significantly easier.

The "official" image is [asciidoctor/docker-asciidoctor](https://hub.docker.com/r/asciidoctor/docker-asciidoctor/).
I have a small variant at [heckj/docker-asciidoctor](https://hub.docker.com/r/asciidoctor/docker-asciidoctor/)
that is built to include the gem `rugged` which is providing the git metadata resolution.

### Rendering - using locally installed asciidoctor & tooling

```bash
cd docs

asciidoctor-epub3 -v -t -D output \
  using-combine-book.adoc

asciidoctor-pdf -v -t -D output \
  using-combine-book.adoc

asciidoctor -v -t -D output \
  -r ./lib/google-analytics-docinfoprocessor.rb \
  using-combine-book.adoc
```

### Rendering - using a docker-based toolchain

You can do all this rendering locally with docker. Do this from the **top** of the repository:

```bash
# get the docker image loaded locally
docker pull heckj/docker-asciidoctor

# render the HTML, results will appear in `output` directory
docker run --rm -v $(pwd):/documents/ --name asciidoc-to-html heckj/docker-asciidoctor asciidoctor -v -t -D /documents/output -r ./docs/lib/google-analytics-docinfoprocessor.rb docs/using-combine-book.adoc

# render a PDF, results will appear in `output` directory
docker run --rm -v $(pwd):/documents/ --name asciidoc-to-pdf heckj/docker-asciidoctor asciidoctor-pdf -v -t -D /documents/output docs/using-combine-book.adoc

# render an epub3 file, will should appear in `output` directory
docker run --rm -v $(pwd):/documents/ --name asciidoc-to-epub3 heckj/docker-asciidoctor asciidoctor-epub3 -v -t -D /documents/output docs/using-combine-book.adoc

# copy in the images for the HTML
cp -r docs/images output/images
```

A variation of these commands are included in the [`.travisCI`](.travis.yml) build configuration.

## Link Validation

There's an NPM package that will hit a page and do a scan for broken links: https://www.npmjs.com/package/broken-link-checker[broken-link-checker].

To install:

    npm install broken-link-checker

To run it against the live site:

    ./node_modules/.bin/blc http://heckj.github.io/swiftui-notes/ | grep BROKEN

## Command-line build and test

    xcodebuild test -scheme SwiftUI-Notes -allowProvisioningUpdates
