# Diagramming

RxMarbles diagramming tool

documented: <https://flames-of-code.netlify.com/blog/rx-marbles/>
source: <https://bitbucket.org/achary/rx-marbles/src/master/>
diagram syntax: <https://bitbucket.org/achary/rx-marbles/src/0f5d57bb309491a979f10d07d4aa7ecff3e4084e/docs/syntax.md?fileviewer=file-view-default>

## install

    virtualenv .venv
    source .venv/bin/activate
    pip3 install -r requirements.txt

## generate and move to use them in the content

    marblesgen -v diagrams/*
    mv *.svg ../docs/images/diagrams/
