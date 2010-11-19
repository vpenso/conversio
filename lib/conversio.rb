require 'conversio/converter'
require 'conversio/pygmentizer'
require 'conversio/htmltoc'

module Conversio
  class Template
  end
end

# find the template directory
templates = File.join(File.dirname(File.expand_path(__FILE__)),'..','templates')
# find the ERB templates 
Dir.glob("#{templates}/*.erb") do |template|
  # add the template as constant to the class Templates
  Conversio::Template.const_set(
    File.basename(template,".erb").upcase, 
    File.read(template))
end

