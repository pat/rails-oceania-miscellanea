require 'lib/thinking_sphinx/client'
require 'lib/thinking_sphinx/client/filter'
require 'lib/thinking_sphinx/client/message'
require 'lib/thinking_sphinx/client/response'

client = ThinkingSphinx::Client.new("localhost", 3313)
begin
  results = client.excerpts(
    :docs             => [
      "John Smith is my good friend",
      "this is another test text to be highlighted"
    ],
    :words            => "John Smith",
    :index            => "people",
    :before_match     => "<b>",
    :after_match      => "</b>",
    :chunk_separator  => " ... ",
    :limit            => 400,
    :around           => 15
  )
  
  results.each_with_index do |result, id|
    puts "n=#{id+1}, res=#{result}"
  end
rescue ThinkingSphinx::VersionError, ThinkingSphinx::ResponseError => err
  puts "Error: #{err}."
end