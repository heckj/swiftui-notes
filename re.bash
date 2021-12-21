#!/bin/bash

# Joe's Handy Rebuild-it-all-and-test-things script
#
# to rebuild the HTML locally (using Docker) and open it for inspection:
#   export OPENIT=1
#   ./re.bash

# if you want to just rebuild, but not open, leave off the "OPENIT" setting
# if you want to rebuild and open everything, you can set all the
# environment variables like so:
#
#   export REBUILDEPUB=1
#   export REBUILDPDF=1
#   export OPENIT=1
#   ./re.bash

# NOTE(heckj) 20nov2019 - no longer generating the marble diagrams
#echo "generating diagrams"
#docker run --rm -i -v $(pwd)/marbles/diagrams:/data --name rxmarbles heckj/rxmarbles
#mv $(pwd)/marbles/diagrams/*.svg $(pwd)/docs/images/diagrams/

echo "Rendering HTML"
# render the HTML, results will appear in `output` directory
docker run --platform linux/amd64 --rm -v $(pwd):/documents/ --name asciidoc-to-html asciidoctor/docker-asciidoctor asciidoctor -v -t -D /documents/output -r ./docs/lib/google-analytics-docinfoprocessor.rb docs/using-combine-book.adoc
# output appears into ./output/using-combine-book.html
docker run --platform linux/amd64 --rm -v $(pwd):/documents/ --name asciidoc-to-html asciidoctor/docker-asciidoctor asciidoctor -v -t -D /documents/output -r ./docs/lib/google-analytics-docinfoprocessor.rb docs_zh-CN/using-combine_zh-CN.adoc

# copy in the images for the HTML
mkdir -p output/images
cp -r docs/images/* output/images

if [ -n "${OPENIT}" ]; then
    open output/using-combine-book.html
fi

# if ENV VAR 'REBUILDPDF' is set, then invoke
if [ -n "${REBUILDPDF}" ]; then
# render a PDF, results will appear in `output` directory
    echo "Rendering PDF"
    docker run --platform linux/amd64 --rm -v $(pwd):/documents/ --name asciidoc-to-pdf asciidoctor/docker-asciidoctor asciidoctor-pdf -v -t -D /documents/output docs/using-combine-book.adoc
    if [ -n "${OPENIT}" ]; then
        open output/using-combine-book.pdf
    fi
fi

# if ENV VAR 'REBUILDEPUB' is set, then invoke
if [ -n "${REBUILDEPUB}" ]; then
# render an epub3 file, will should appear in `output` directory
    echo "Rendering ePub"
    docker run --platform linux/amd64 --rm -v $(pwd):/documents/ --name asciidoc-to-epub3 asciidoctor/docker-asciidoctor asciidoctor-epub3 -v -t -D /documents/output docs/using-combine-book.adoc
    if [ -n "${OPENIT}" ]; then
        open output/using-combine-book.epub
    fi
fi
