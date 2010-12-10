Conversio by Jörg Behrendt and Victor Penso

# Description

Renders plain text files with [Markdown][1] syntax to XHTML pages.  User can define their own Ruby ERB templates to customize the XHTML page generation. Also the creation of a table of content using the HTML header elements (like `<h1>`) and the syntax high-lighting of code snippets is supported.

## Installation 

Conversio RubyGem: 

    gem install conversio

Syntax high-lighting is done with Phyton [Pygments][2]:

    easy_install pygments

## Usage Examples

Take a look to the help text:

    conversio -h

Convert all files called `*.markdown` or `*.md` inside a defined directory and all sub-directories into HTML and store them in the destination directory.

    conversio ~/docs/path/to/files ~/public/path

Create a single `readme.html` file including a table of content by 
using the 'dark' template:

    conversio -t -p dark readme.markdown

### Syntax High-Lighting

Using the `-c` option syntax colorization can be enabled. Conversio will inspect all code blocks for a syntax tag in the first line. This tag needs to be part of the code block (indented with four spaces) and is prefixed with two dashes followed by the language definition. For example to high-light a code block as Ruby write `--ruby` as first line or for C++ `--c++`. If this tag is not present Conversio will not apply any high-lighting. The tag itself is passes to Pygments, therefore any
language supported by it can be high-lighted.

For a list of supported languages type:

    pygmentize -L lexers

## License

GPLv3 - see the COPYING file.

[1]: http://daringfireball.net/projects/markdown/
[2]: http://pygments.org/
