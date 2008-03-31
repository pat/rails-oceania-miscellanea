require 'erb'
require 'RedCloth'

template = ERB.new open("template.html.erb").read

Dir["*.textile"].each do |file|
  content = RedCloth.new(open(file).read).to_html
  open(file.gsub(/textile$/, 'html'), 'w') do |f|
    f.print template.result(binding)
  end
end