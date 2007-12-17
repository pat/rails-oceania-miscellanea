Gem::Specification.new do |s|
  s.name = %q{ruby2ruby}
  s.version = "1.1.7"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Davis"]
  s.cert_chain = nil
  s.date = %q{2007-08-21}
  s.default_executable = %q{r2r_show}
  s.description = %q{ruby2ruby provides a means of generating pure ruby code easily from ParseTree's Sexps. This makes making dynamic language processors much easier in ruby than ever before.}
  s.email = %q{ryand-ruby@zenspider.com}
  s.executables = ["r2r_show"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/r2r_show", "lib/ruby2ruby.rb", "test/test_ruby2ruby.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://seattlerb.rubyforge.org/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = %q{seattlerb}
  s.rubygems_version = %q{0.9.5}
  s.summary = %q{ruby2ruby provides a means of generating pure ruby code easily from ParseTree's Sexps.}
  s.test_files = ["test/test_ruby2ruby.rb"]

  s.add_dependency(%q<ParseTree>, ["> 0.0.0"])
  s.add_dependency(%q<hoe>, [">= 1.3.0"])
end
