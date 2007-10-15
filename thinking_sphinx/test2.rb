require 'lib/thinking_sphinx/client'
require 'lib/thinking_sphinx/client/filter'
require 'lib/thinking_sphinx/client/message'
require 'lib/thinking_sphinx/client/response'

client = ThinkingSphinx::Client.new("localhost", 3312)
begin
  results = client.excerpts(
    :docs             => [
      "this is my test text to be highlighted",
      "this is another test text to be highlighted"
    ],
    :words            => "test text",
    :index            => "edition",
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