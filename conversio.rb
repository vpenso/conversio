#!/usr/bin/env ruby 

require 'rubygems'
require 'erb'
require 'yaml'
require 'ftools'
require 'fileutils'
require 'pathname'
require 'getoptlong'
require 'lib/pygmentizer'
require 'lib/converter'
require 'lib/htmltoc'


help = <<EOF
Synopsis
--------

  #{File.split(__FILE__)[-1]}: Renders Markdown plain text files to HTML 

Purpose
-------

Uses Ruby ERB Templates to generate XHTML documents rendered from Markdown
plain text files.

Usage
-----

#{File.split(__FILE__)[-1]} [OPTIONS] SRC [DST]

SRC: File or directory containing the Markdown formated plain text
DST: Target directory for the XHTML output.

Options
-------

-c, --config

  Creates a personal configuration file in ~/.conversiorc

-e, --engine:

  Select the Markdown parser to be used:
  * 'bluecloth' (default)
  * 'kramdown'

-h, --help:

  show help

-s --style DST:

  Write a resonable default CSS configuration to DST.

-t, --template FILE:

  FILE containing an ERB template with:
  * '<%= content %>' to mark the postion inside the body tag
    to place the passed in content.
  * '<%= style %>' to mark the position for placing CSS.

--template-default:

  Prints the default template used when no template is specified
  by the user. Take it as an very simple example to write your
  own template files.
EOF

default_template = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
   PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <link href="./style/reset.css" rel="stylesheet" type="text/css"> 
  <link href="./style/content.css" rel="stylesheet" type="text/css"> 
  <link href="./style/pygments.css" rel="stylesheet" type="text/css"> 
</head>
<body>
  <%= @content %>
</body>
</html>
EOF

config = <<EOF
conf:
  colorize: true
  table_of_content: true
EOF


def load_lib(name)
  begin 
      require name
  rescue LoadError
    $stderr.puts "Loading library #{name} failed!"
    exit 1
  end
end

# -------------------------------------------------------------
# class extensions
# -------------------------------------------------------------

class Array
  def resolv_path
    Hash[ *self.collect { |e| [e,e.gsub(/.markdown/,'.html') ] }.flatten ]
  end
end

# -------------------------------------------------------------
# main program
# -------------------------------------------------------------
begin

  # default values
  style = nil
  template = nil
  engine = nil

  # list of user options
  opts = GetoptLong.new(
    [ '--config', '-c', GetoptLong::NO_ARGUMENT],
    [ '--engine', '-e', GetoptLong::OPTIONAL_ARGUMENT],
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--style', '-s', GetoptLong::OPTIONAL_ARGUMENT],
    [ '--template', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--template-default', GetoptLong::NO_ARGUMENT ]
  )

  # parse the options from the command line
  opts.each do |opt, arg|
    case opt
    when '--config'
      open("#{ENV['HOME']}/.conversiorc",'w') { |f| f.write config }
      exit 0
    when '--engine'
      engine = arg
    when '--help' 
      puts help
      exit 0
    when '--style'
      FileUtils::Verbose.cp_r('resources/css/.',"#{arg}/style/")
      exit 0
    when '--template' 
      template = open( arg ){ |file| file.read } if File.exist?(arg)
    when '--template-default' 
      puts default_template
      exit 0
    end
  end

  # get the input source
  src = ARGV[0] || raise("no input defined")
  dst = ARGV[1] # optional parameter!
  # user the default XHTML template if the user hasn't defined its own
  template = default_template if template.nil? 
  converter = Converter.new(template)
  converter.load_parser(engine) unless engine.nil?
  # get all the input files
  input_files = Array.new
  if File.directory?(src) then
    input_files = Dir["#{src}/**/*.markdown"]
  else
    file = File.expand_path(src)
    input_files << file
    src = File.dirname(file) 
  end
  src_dst_pairs = input_files.resolv_path
  # fix the destination path if needed
  unless dst.nil? then
    src_dst_pairs.each_pair do |src_path,dst_path|
      src_dst_pairs[src_path] = dst_path.gsub(/#{src}/,dst)      
    end
  end
  # render the XHTML docs
  src_dst_pairs.each_pair { |s,d| converter.markdown_to_xhtml(s,d) }

  exit 0

rescue => exc
  STDERR.puts "ERROR: #{exc.message}"
  STDERR.puts "  use -h for detailed instructions"
  exit 1
end


