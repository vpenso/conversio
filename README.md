# Conversio

Renders plain text files with [Markdown][1] syntax to XHTML pages. 
User can define their own Ruby ERB templates to customize the 
XHTML page generation. Also the creation of a table of content 
using the HTML header elements (like `<h1>`) and the syntax
high-lighting of code snippets is supported.

## Installation 

Conversio RubyGems: 

    gem install conversio

Syntax high-lighting is done with Pyhton [Pygments][2]:

    easy_install pygments

## Usage

    conversio -h


[1]: http://daringfireball.net/projects/markdown/
[2]: http://pygments.org/
