# pandoc-goalscape

[Pandoc custom writer](http://johnmacfarlane.net/pandoc/README.html#custom-writers) for generating [Goalscape](http://www.goalscape.com) Project files (.gsp)

## Installation

* [Install Pandoc](http://pandoc.org/installing.html) (v1.13 or later).
* Download `goalscape.lua` and `default.goalscape` and put somewhere in your PATH.

## Usage
To convert the Markdown file `example1.md` into the Goalscape Project file `example1.gsp`, use the following command:

```
pandoc -t goalscape.lua --template=default.goalscape -o example1.xml example.md
```
