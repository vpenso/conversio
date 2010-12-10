require 'fileutils'

module Conversio

class Converter

  attr_accessor :table_of_content, :color

  def initialize(template)
    @template = template
    @table_of_content = false
    @color = false
    # Holds the input Markdown plain text
    @source = nil
    # Hold Markdown rendered to HTML
    @content = nil
    # Hold the finished XHTML document
    @result = nil
    # load the default parser
    @parser = 'bluecloth'
    load_parser(@parser)
  end

  def markdown_to_xhtml(src,dst)
    @source = open(src).readlines.join
    colorize() if @color 
    parse()    
    generate_table_of_content() if @table_of_content
    render()
    # write the HTML file
    FileUtils::mkdir_p(File.dirname(dst)) unless File.exists?(File.dirname(dst))
    open(dst,'w') { |f| f.write @result }
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
    @parser = parser
  end

  private

  def load_template(tpl)
    puts "Loading template : "+tpl.to_s
    raise "Couldn't open ERB template: #{tpl}" unless File.exists?(File.expand_path(tpl))
    return open(File.expand_path(tpl)).readlines.join
  end

  def parse
    raise "Define source before rendering!" if @source == nil
    case @parser
    when 'bluecloth'
      @content = BlueCloth::new(@source).to_html
    when 'kramdown'
      @content = Kramdown::Document.new(@source).to_html
    else 
      puts "Markdown parser #{@parser} not supported yet"
    end
  end

  def colorize 
     @source = Pygmentizer.new.transform_code_blocks(@source)
  end

  def generate_table_of_content #füge zum geparsten Text ein Inhaltsverzeichnis hinzu -> davor parsen
    raise "No content to generate table of content - Run the parser first!" if @content == nil
    @content = HTMLTableOfContent.new(@content).get_html()
  end

  def render(values = {})
    values.store(:content, @content)
    @result = ERB.new(@template).result(binding)
  end

end

end
