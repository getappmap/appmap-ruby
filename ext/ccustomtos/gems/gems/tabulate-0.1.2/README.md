tabulate
===========

Create fancy command line tables with ease.

Builtin styles: 

"simple", "plain", "fancy", "sqlite", "plain2", "plain\_alt", "legacy". 

PLEASE BE AWARE this is my first gem :) .

Features
--------

* Builtin styles
* Colored data input support
* Double width east Asian character support with ruby 1.9

Examples
--------

    source = [["\e[31maht\e[m",3],[4,"\e[33msomething\e[m"],['s',['abc','de']]]
    labels = ["a",'b']
    puts tabulate(labels, source, :indent => 4, :style => 'legacy')

will produce a table like the following, with "aht" colored in red and
"something" in yellow.

    +-----+-----------+
    | a   | b         |
    +=====+===========+
    | aht | 3         |
    | 4   | something |
    | s   | abc       |
    |     | de        |
    +-----+-----------+

Requirements
------------

Nil.
East Asian character support requires ruby 1.9 and above.

Install
-------

    gem install tabulate

License
-------

MIT

