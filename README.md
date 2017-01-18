# pandoc-goalscape

[Pandoc custom writer](http://johnmacfarlane.net/pandoc/README.html#custom-writers) for generating [Goalscape](http://www.goalscape.com) Project files (.gsp)

## Installation

* [Install Pandoc](http://pandoc.org/installing.html) (v1.13 or later).
* Download `goalscape.lua` and `default.goalscape` and put somewhere in your PATH.

## Usage Example

```markdown
# Title

## Subgoal 1

This text will appear in the **Notes** tab, which supports:

- *simple* styling
- [links](http://pandoc.org)
- and lists

## Subgoal 2

## Subgoal 3
```

To convert the Markdown file `example1.md` into the Goalscape Project file `example1.gsp`, use the command:

```
pandoc -t goalscape.lua --template default.goalscape --filter ./pandoc-filter-goalscape.php example1.md > example1.gsp
```

![](/../gh-pages/images/example1.png?raw=true)