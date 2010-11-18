module Conversio


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

end
