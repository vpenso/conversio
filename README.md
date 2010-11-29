Conversio by Jörg Behrendt and Victor Penso

# Description

Renders plain text files with [Markdown][1] syntax to XHTML pages. 
User can define their own Ruby ERB templates to customize the 
XHTML page generation. Also the creation of a table of content 
using the HTML header elements (like `<h1>`) and the syntax
high-lighting of code snippets is supported.

## Installation 

Conversio RubyGem: 

    gem install conversio

Syntax high-lighting is done with Pyhton [Pygments][2]:

    easy_install pygments

## Usage Examples

Take a look to the help text:

    conversio -h

Convert all files called `*.markdown` inside a defined directory 
and all sub-directories into HTML and store the in the destination
directory.

    conversio ~/docs/path/to/files ~/public/path

Create a single `readme.html` file including a table of content by 
using the 'dark' template:

    conversio -t -p dark readme.markdown

## License

GPLv3 - see the COPYING file.

[1]: http://daringfireball.net/projects/markdown/
[2]: http://pygments.org/
