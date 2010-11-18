# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{conversio}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Penso"]
  s.date = %q{2010-11-18}
  s.default_executable = %q{conversio}
  s.description = %q{Renders Markdown plain text files to HTML}
  s.email = %q{v.penso@gsi.de}
  s.executables = ["conversio"]
  s.extra_rdoc_files = ["bin/conversio", "lib/conversio.rb", "lib/conversio/converter.rb", "lib/conversio/htmltoc.rb", "lib/conversio/pygmentizer.rb"]
  s.files = ["README.md", "HISTORY.md", "bin/conversio", "conversio.gemspec", "lib/conversio.rb", "lib/conversio/converter.rb", "lib/conversio/htmltoc.rb", "lib/conversio/pygmentizer.rb"]
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Conversio"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{conversio}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Renders Markdown plain text files to HTML}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
