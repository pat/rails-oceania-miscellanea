require 'merb/test/fake_request'
require 'merb/test/hpricot'
include HpricotTestHelper

# Create a FakeRequest suitable for passing to Controller.build
def fake_request(path="/",method='GET')
  method = method.to_s.upcase
  Merb::Test::FakeRequest.with(path, :request_method => method)
end

# Turn a named route into a string with the path
def url(name, *args)
  Merb::Router.generate(name, *args)
end


# For integration/functional testing


def request(verb, path)
  response = StringIO.new
  @request = Merb::Test::FakeRequest.with(path, :request_method => (verb.to_s.upcase rescue 'GET'))
  
  yield @request if block_given?
  
  @controller, @action = Merb::Dispatcher.handle @request, response
end

def get(path)
  request("GET",path)
end
