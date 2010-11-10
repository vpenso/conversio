#!/usr/bin/env ruby
require 'erb'
require 'yaml'
require 'ftools'
require 'fileutils'
require 'pathname'
require 'bluecloth'
require 'getoptlong'


module Conversio

class UI

  def self.folder(folder, destfolder, template)
      Dir.foreach(folder) do |file|
         Converter.new(template).markdown_to_xhtml(folder+"/"+file,destfolder.to_s+"/"+file.gsub(".markdown","_conversio.html")) if File.extname(file) == ".markdown"
      end        
  end


  def self.file(file, destfile, template)
      Converter.new(template).markdown_to_xhtml(file, destfile)  
  end

  def self.simple_folder(folder, template)
      Dir.foreach(folder) do |file|
         Converter.new(template).markdown_to_xhtml(folder+"/"+file,folder+"/"+file.gsub(".markdown","_conversio.html")) if File.extname(file) == ".markdown"
      end        
  end

  def self.simple_file(file, template)
      Converter.new(template).markdown_to_xhtml(file,file.gsub(".markdown","_conversio.html"))  
  end

end


class Converter
  attr_accessor :source, :content, :globals, :meta_data


  def initialize(template)
    #check if config / web / docs folder exists
    @template = load_template(File.expand_path("~/conversio/config/standart.erb")) if template == nil
    @template = load_template(File.expand_path(template)) if template != nil
    # Empty metadata hashtable
    @meta_data = Hash.new
    # Holds the input Markdown plain text
    @source = nil
    # Hold Markdown rendered to HTML
    @content = nil
    # Hold the finished XHTML document
    @result = nil  
  end

  

  def check_source_input(source) 
    raise "File " + source.to_s + " doesnt exist" if !File.exist?(source)
    raise "File " + source.to_s + " doesnt end with .markdown" if (File.extname(source) != ".markdown")    
  end
 

  def get_config_out_of_source()
    start = @source.index("|--")
    ende = @source.index("--|")
    if start != nil and ende != nil then
      yamlheader = @source[start+3,ende-start-3]
      @meta_data = YAML.load(yamlheader)
      splitted =  @source.split('--|',2)
      @source = splitted[1]
    else
      puts "detected markdown file without own configuration. loading standart configuration" 
      @meta_data = YAML.load_file("~/conversio/config/standartconfig.yaml")
    end
  end

  def markdown_to_xhtml(source,dest)
    sourcePath = File.expand_path(source).to_s     
    check_source_input(sourcePath);
    read_file(sourcePath);
    File.makedirs(File.dirname(dest)) if File.exists?(File.dirname(dest)) != true
    get_config_out_of_source() 

    @meta_data['conf']['title'] = File.basename(source) if @meta_data.has_key?('conf') and 
    @meta_data['conf'].has_key?('title') != true

    colorize() if 
      @meta_data.has_key?('conf') and 
      @meta_data['conf'].has_key?('colorize') and
      @meta_data['conf']['colorize'] 
    parse()    
    generate_table_of_content() if 
      @meta_data.has_key?('conf') and 
      @meta_data['conf'].has_key?('table_of_content') and
      @meta_data['conf']['table_of_content']  

    load_template(File.expand_path(@meta_data['conf']['template'].to_s)) if 
      @meta_data.has_key?('conf') and 
      @meta_data['conf'].has_key?('template') and
      @meta_data['conf']['template']   

    render()
    write_html(dest)
  end


  def write_html(file)
    raise "Document not generated yet!" if @result == nil
    puts "Save as: "+file.to_s    
    myfile = open(file,'w') { |f| f << @result }
    myfile.close() if !myfile.closed?
  end


  def load_parser(parser)
    begin
      case parser
      when 'bluecloth'
        require 'bluecloth'
      when 'kramdown'
        require 'kramdown'
      else
        raise "Parser '#{parser}' is not a known Markdown library"
      end
    rescue LoadError
      raise "Couldn't load #{parser}."
    end
    return parser
  end

  def load_template(tpl)
    puts "Loading template : "+tpl.to_s
    raise "Couldn't open ERB template: #{tpl}" unless File.exists?(File.expand_path(tpl))
    return open(File.expand_path(tpl)).readlines.join
  end


  def read_file(file)
    if File.file?(file) then
      @source = open(file).readlines.join
    else
      raise "Couldn't open source file #{source_file}"
    end
  end


  def parse
    raise "Define source before rendering!" if @source == nil
      @content = BlueCloth::new(@source).to_html    
  end

  def colorize #Färbe Codeblöcke in der Source -> danach parsen
      raise "No content to colorize!" unless 
      @source.instance_of?(String) and
      @content == nil
      @source = Pygmentizer.new.transform_code_blocks(@source)
  end

  def generate_table_of_content #füge zum geparsten Text ein Inhaltsverzeichnis hinzu -> davor parsen
    puts "Generate TOC"
    raise "No content to generate table of content - Run the parser first!" if @content == nil
    @content = HTMLTableOfContent.new(@content).get_html()
  end

  def render(values = {})
    raise "No content to render!" if @content == nil   
    values.store(:content, @content)
    values.store(:meta_data, @meta_data) 
    values.store(:globals, @globals)
    @result = ERB.new(@template).result(binding)
  end

end



class Pygmentizer

  def self.respond_to?( command )
   return true if `which #{command}`.empty?
   return false
 end
  
  def self.run(command, input='')
   puts command if $DEBUG
   IO.popen(command, 'r+') do |io|
     io.puts input
     io.close_write
     return io.read
   end
  end



  def output(string)
    @output << "#{string}\n"
  end

  def transform_code_blocks(text)
    puts "pygmentizing..."
    raise RuntimeError, "pygmentize not in path" if 
    Pygmentizer::respond_to?("pygmentize")
    @input_by_line = Array.new 
    text.each_line { |line| @input_by_line << line.chop }
    @output = String.new
    buffer = Array.new
    rec = false
    @input_by_line.each do |line|
      # true if a Markdown code block is found
      rec = true if !rec and line =~ /^    /
      # store the code block into buffer
      if rec and line =~ /^    / then
        # remove the leading 4 spaces
        line = line.gsub(/^    /,'')
        buffer << line
      # End of code block
      elsif rec 
        block_to_html(buffer)
        # Wipe the buffer
        buffer.clear
        rec = false
      # Anyting beside code blocks will be output
      else 
        output(line)
      end
    end
    return @output
  end
  

  def block_to_html(block)
    style = get_style(block[0])
    unless style.empty? then
      # remove the style information from the code block
      block.slice!(0)
      output(highlight(block.join("\n"),style))
    else
      # Code blocks without style information will be
      # put to output includeing the 4 leading spaces
      block.each {|line| output("    #{line}") }
      output("")
    end
  end


  def get_style(string)
    return string.gsub(/--/,'').strip if string =~ /^--[a-z]* */
    return ""
  end
  
  def highlight(string, style)
    return Pygmentizer::run("pygmentize -f html -l #{style}", string) << "\n"
  end
end




class HTMLTableOfContent
  
  attr_accessor :numbering, :table_of_content_div_class
  
  def initialize(html_input)
    @numbering = true
    @table_of_content_div_class = 'toc'
    # Variables
    @html_input = Array.new
    @heading_elements = Array.new
    html_input.split("\n").each { |l| @html_input << l }
    scan_for_heading_elements()
    numbers()
  end

  def get_html_with_anchors()
    inject_anchors()
    return @html_input.join("\n")
  end

  def get_html_table_of_content()
    output = String.new
    @heading_elements.each do |heading|  
      index, level, content, anchor, number = heading
      level = level.to_i
      next if level > 3 # only h1,h2, and h3 tags are used
      space = '&nbsp;&nbsp;'
      case level
      when 2 then output << space
      when 3 then output << space << space
      end
      content = "#{number}&nbsp;#{content}" if numbering?
      output << %{<a href="##{anchor}">#{content}</a><br/>\n}
    end
    return %{<div class="#{@table_of_content_div_class}">\n#{output}</div>\n}
  end

  def get_html()
    return get_html_table_of_content() << "\n" << get_html_with_anchors
  end

  protected
  
  def numbering?
    return @numbering
  end

  def scan_for_heading_elements()
    @html_input.each_index do |index|
      if @html_input[index] =~ %r{<h(\d)(.*?)>(.*?)</h\1>$}m then
        # Pattern match values:
        #  $1 -- header tag level, e.g. <h2>...</h2> will be 2
        #  $3 -- content between the tags
        @heading_elements << [index, $1, $3, anchor($3)]
      end
    end
  end

  # Transforms the input string into a valid XHTML anchor (ID attribute).
  # 
  #   anchor("Text with spaces")                   # textwithspaces
  #   anchor("step 1 step 2 step: 3")              # step1step2step3
  def anchor(string)
    alnum = String.new
    string.gsub(/[[:alnum:]]/) { |c| alnum << c }
    return alnum.downcase
  end

  def numbers()
    chapters = 0
    sections = 0
    subsections = 0
    @heading_elements.each_index do |index|
      level = @heading_elements[index][1].to_i
      case level
      when 1
        chapters = chapters.next
        @heading_elements[index] << "#{chapters}"
        sections = 0
        subsections = 0
      when 2
        sections = sections.next
        @heading_elements[index] << "#{chapters}.#{sections}"
        subsections = 0
      when 3
        subsections = subsections.next
        @heading_elements[index] << "#{chapters}.#{sections}.#{subsections}"
      end
    end
  end

  def inject_anchors()
    @heading_elements.each do |heading|
      line = String.new
      index = heading[0]
      level = heading[1].to_i
      content = heading[2]
      anchor = heading[3]
      next if level > 3 # only h1,h2, and h3 tags are used 
      if numbering? then 
        number = heading[4] 
        line = %{<h#{level}><a name="#{anchor}"></a>#{number}&nbsp;#{content}</h#{level}>}
      else
        line = %{<h#{level}><a name="#{anchor}"></a>#{content}</h#{level}>}
      end
      @html_input[index] = line
    end
  end

end

end





opts = GetoptLong.new(
   [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
   [ '--destination', '-d', GetoptLong::OPTIONAL_ARGUMENT ],
   [ '--template', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
   [ '--path','-p', GetoptLong::REQUIRED_ARGUMENT ]
)


source = nil
destination = nil
template = nil

   opts.each do |opt, arg|
       case opt
          when '--help'
             puts "Use:\n--path         -p  path/to/file/or/folder  to set up source file/folder path       (REQUIRED)\n--destination  -d  path/to/file/or/folder  to set up destination file/folder path  (OPTIONAL)\n--template     -t  path/to/template/file   to use an own template                  (OPTIONAL)\n--help         -h                          to show up this message"
             exit
          when '--path'  
             source = arg.to_s
          when '--destination'
             destination = arg.to_s
          when '--template'
             template = arg.to_s
       end
    end

raise "No path. Use -p path/to/file" if source == nil
Conversio::UI.simple_file(source,template) if !File.directory?(source) and !destination
Conversio::UI.file(source,destination,template) if !File.directory?(source) and destination and !File.directory?(destination)
Conversio::UI.simple_folder(source,template) if File.directory?(source) and !destination
Conversio::UI.folder(source,destination,template) if File.directory?(source) and destination and File.directory?(destination)

