require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Request do
  include Mocha::SetupAndTeardown
  
  class GoodPosts < Merb::Controller
    def show() end
  end
  
  before(:each) do
    setup_stubs
    @in = Merb::Test::FakeRequest.new
    Merb::Request.any_instance.stubs(:route_params).returns({})
  end
  
  after(:each) do
    teardown_stubs
  end
  
  it "should parse POST body into params" do
    @in.post_body = "title=hello%20there&body=some%20text&user[roles][]=admin&user[roles][]=superuser&commit=Submit"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.params[:title].should == "hello there"
    request.params[:body].should == "some text"
    request.params[:commit].should == "Submit"
    request.params[:user][:roles].class.should == Array
    request.params[:user][:roles][0].should == "admin"
    request.params[:user][:roles][1].should == "superuser"
  end
  
  it "should parse POST body into params unless Content-Type header is set explicitly" do
    input = "title=hello%20there&body=some%20text&commit=Submit"
    @in.post_body = input
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = 'text/plain'
    request = Merb::Request.new(@in)
    request.params[:title].should be_nil
    request.params[:body].should be_nil
    request.params[:commit].should be_nil
    request.raw_post.should == input
  end
  
  it "should parse PUT body into params" do
    @in.post_body = "title=hello%20there&body=some%20text&commit=Submit"
    @in['REQUEST_METHOD'] = 'PUT'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.params[:title].should == "hello there"
    request.params[:body].should == "some text"
    request.params[:commit].should == "Submit"
  end
  
  it "should parse PUT body into params unless Content-Type header is set explicitly" do
    input = "title=hello%20there&body=some%20text&commit=Submit"
    @in.post_body = input
    @in['REQUEST_METHOD'] = 'PUT'
    @in['CONTENT_TYPE'] = 'text/plain'
    request = Merb::Request.new(@in)
    request.params[:title].should be_nil
    request.params[:body].should be_nil
    request.params[:commit].should be_nil
    request.raw_post.should == input
  end
    
  it "should parse Query String into params" do
    @in['QUERY_STRING'] = "title=hello%20there&body=some%20text&commit=Submit"
    request = Merb::Request.new(@in)
    request.params[:title].should == "hello there"
    request.params[:body].should == "some text"
    request.params[:commit].should == "Submit"
  end
  
  it "shouldn't explode on key only query" do
    @in['QUERY_STRING'] = "pop"
    request = Merb::Request.new(@in)
    request.params.has_key?(:pop).should be_true
  end
  
  it "shouldn't explode on value only query" do
    @in['QUERY_STRING'] = "=bang"
    request = Merb::Request.new(@in)
    request.params.has_value?('bang').should be_true
  end
  
  it "should handle file upload for multipart/form-data posts" do
    m = Merb::Test::Multipart::Post.new :file => File.open(FIXTURES / 'sample.txt')
    body, head = m.to_multipart
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = head
    @in['CONTENT_LENGTH'] = body.length
    @in.post_body = body
    request = Merb::Request.new(@in)
    request.params[:file].should_not be_nil
    request.params[:file][:tempfile].class.should == Tempfile
    request.params[:file][:content_type].should == 'text/plain'
  end
  
  # it "multipart/form-data handles multiple form fields" do
  #   m = Merb::Test::Multipart::Post.new :foo => 'bario', 'files[]' => File.open(FIXTURES / 'sample.txt')
  #   m.push_params 'files[]' => File.open(FIXTURES / 'foo.rb') 
  #   body, head = m.to_multipart
  #   @in['REQUEST_METHOD'] = 'POST'
  #   @in['CONTENT_TYPE'] = head
  #   @in['CONTENT_LENGTH'] = body.length
  #   @in.post_body = body
  #   request = Merb::Request.new(@in)
  #   params[:foo].should == 'bario'
  #   params[:files].should_not be_nil
  #   params[:files].should be_kind_of(Array)
  #   params[:files].first[:tempfile].class.should == Tempfile
  # end
  
  it "Json Post Body is parsed into params" do
    @in.post_body = "{\"title\":\"hello there\",\"body\":\"some text\"}"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "text/x-json"
    request = Merb::Request.new(@in)
    request.params[:title].should == "hello there"
    request.params[:body].should == "some text"
  end
  
  it "Json Post Body is not parsed into params if Merb::Request::parse_json_params = false" do
    Merb::Request::parse_json_params = false
    @in.post_body = "{\"title\":\"hello there\",\"body\":\"some text\"}"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "text/x-json"
    request = Merb::Request.new(@in)
    request.params[:title].should be_nil
    request.params[:body].should be_nil
    Merb::Request::parse_json_params = true
  end
  
  it "should parse a JSON body into params when charset provided" do
    @in.post_body = "{\"title\":\"hello there\",\"body\":\"some text\"}"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "text/x-json; charset=utf-8"
    request = Merb::Request.new(@in)
    request.params[:title].should == "hello there"
    request.params[:body].should == "some text"
  end
  
  it "should parse an XML body into params when charset provided" do
    @in.post_body = "<root><title>hello there</title><body>some text</body></root>"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "text/xml; charset=utf-8"
    request = Merb::Request.new(@in)
    request.params[:root][:title].should == "hello there"
    request.params[:root][:body].should == "some text"
  end
  
  it "should handle hash-style form fields in multipart/form-data" do
    m = Merb::Test::Multipart::Post.new :foo => 'bario',
         'files[foo][file]' => File.open(FIXTURES / 'foo.rb'),
         'files[foo][name]' => "Foo",
         'files[bar][file]' => File.open(FIXTURES / 'foo.rb'),
         'files[bar][name]' => "Bar",
         'deep[files][foobar][]' => File.open(FIXTURES / 'foo.rb'),
         'regular_fields[user][name]' => "John Doe",
         'regular_fields[user][email]' => "jdoe@example.com"
    body, head = m.to_multipart
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = head
    @in['CONTENT_LENGTH'] = body.length
    @in.post_body = body
    request = Merb::Request.new(@in)
    
    request.params.should_not include(:"files[foo]")
    request.params.should_not include(:"files[bar]")
    request.params.should_not include(:"regular_fields[user]")
    request.params.should_not include(:"deep[files]")
    
    request.params[:files][:foo][:name].should == "Foo"
    request.params[:files][:foo][:file].should include(:filename)
    request.params[:files][:foo][:file][:tempfile].class.should == Tempfile
    request.params[:files][:bar][:name].should == "Bar"
    request.params[:files][:bar][:file].should include(:filename)
    request.params[:files][:bar][:file][:tempfile].class.should == Tempfile
    
    request.params[:deep][:files][:foobar].class.should == Array
    request.params[:deep][:files][:foobar].size.should == 1
    
    request.params[:regular_fields][:user][:name].should == "John Doe"
  end
  
  it "should understand PUT if passed as _method in query string for RESTful form dispatch" do
    @in.post_body = "title=hello"
    @in['QUERY_STRING'] = '_method=put'
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.method.should == :put
    request.params[:title].should == "hello"
  end

  it "should understand DELETE if passed as _method in query string for RESTful form dispatch" do
    @in.post_body = "title=hello"
    @in['QUERY_STRING'] = '_method=delete'
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)    
    request.method.should == :delete
    request.params[:title].should == "hello"
  end
  
  it "should understand PUT if passed as _method in request body for RESTful form dispatch" do
    @in.post_body = "_method=put&title=hello"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.method.should == :put
    request.params[:title].should == "hello"
  end

  it "should understand DELETE if passed as _method in request body for RESTful form dispatch" do
    @in.post_body = "_method=delete&title=hello"
    @in['REQUEST_METHOD'] = 'POST'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.env['REQUEST_METHOD'].should == 'POST'
    request.method.should == :delete
    request.params[:title].should == "hello"
  end

  it "should not raise a NotFound exception when the controller class exists" do
    @in['REQUEST_URI'] = "/good_posts/show/1"
    @in['REQUEST_METHOD'] = 'GET'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.stubs(:controller_name).returns("good_posts")
    lambda { request.controller_class }.should_not raise_error(Merb::ControllerExceptions::NotFound)
  end
  
  it "should raise a NotFound exception when the controller does not exist" do
    @in['REQUEST_URI'] = "/bad_posts/show/1"
    @in['REQUEST_METHOD'] = 'GET'
    @in['CONTENT_TYPE'] = "application/x-www-form-urlencoded"
    request = Merb::Request.new(@in)
    request.stubs(:controller_name).returns("bad_posts")
    lambda { request.controller_class }.should raise_error(Merb::ControllerExceptions::NotFound)
  end

  it "should set accept to '*/*' when HTTP_ACCEPT is blank" do
    @in['HTTP_ACCEPT'] = ""
    request = Merb::Request.new(@in)
    request.accept.should == "*/*"
  end

  it "should set accept to '*/*' when HTTP_ACCEPT is empty" do
    @in['HTTP_ACCEPT'] = nil
    request = Merb::Request.new(@in)
    request.accept.should == "*/*"
  end

  it "should set accept to '*/*' when HTTP_ACCEPT is not set" do
    @in.env.delete('HTTP_ACCEPT')
    request = Merb::Request.new(@in)
    request.accept.should == "*/*"
  end
  
  it "should be able to tell you the HTTP method for POST requests without an error" do
    @in['REQUEST_METHOD'] = 'POST'
    request = Merb::Request.new(@in)
    lambda {request.method}.should_not raise_error
    request.method.should == :post
  end
  
  it "should be able to tell you the HTTP method for GET requests without an error" do
    @in['REQUEST_METHOD'] = 'GET'
    request = Merb::Request.new(@in)
    lambda {request.method}.should_not raise_error
    request.method.should == :get
  end
  
  it "multipart_params should return an empty hash if the request is not multipart" do
    request = Merb::Request.new(@in)
    request.send(:multipart_params).should == {}
  end
  
  it "should add namespace to controller name" do
    request = Merb::Request.new(@in)
    request.stubs(:route_params).returns({:controller => 'bar', :namespace => 'foo'})
    request.controller_name.should == "foo/bar"
  end
end
