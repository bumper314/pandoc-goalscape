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
- and flat lists

## Subgoal 2

## Subgoal 3
```

To convert the Markdown file `example1.md` into the Goalscape Project file `example1.gsp`, use the command:

```
pandoc -t goalscape.lua --template default.goalscape --filter ./pandoc-filter-goalscape.php example1.md > example1.gsp
```

![](/../gh-pages/images/ss-example1.png?raw=true)

## Examples To Be Documented

![](/../gh-pages/images/ex-us-constitution.png?raw=true)
![](/../gh-pages/images/ex-king-james-bible.png?raw=true)
![](/../gh-pages/images/ex-animals-importance-even.png?raw=true)
![](/../gh-pages/images/ex-animals-importance-subgoals-even.png?raw=true)
![](/../gh-pages/images/ex-animals-importance-subgoals.png?raw=true)
![](/../gh-pages/images/ex-evaluator.png?raw=true)
![](/../gh-pages/images/ss-naming.png?raw=true)