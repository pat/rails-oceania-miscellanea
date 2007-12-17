require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Test::FakeRequest, ".new(env = {}, method = 'GET', req = StringIO.new)" do
  it "should create request with default enviroment" do
    @mock = Merb::Test::FakeRequest.new
    @mock.env.should == Merb::Test::FakeRequest::DEFAULT_ENV
  end
  
  it "should override default env values passed in HTTP format" do
    @mock = Merb::Test::FakeRequest.new('HTTP_ACCEPT' => 'nothing')
    @mock['HTTP_ACCEPT'].should == 'nothing'
  end
  
  it "should override default env values passed in symbol format" do
    @mock = Merb::Test::FakeRequest.new(:http_accept => 'nothing')
    @mock['HTTP_ACCEPT'].should == 'nothing'
  end
  
  it "should change :cookies into HTTP_COOKIE" do
    @mock = Merb::Test::FakeRequest.new(:cookies => 'icanhazcookie=true')
    @mock['HTTP_COOKIE'].should == 'icanhazcookie=true'
  end
  
  it "should set body to an empty StringIO" do
    @mock = Merb::Test::FakeRequest.new
    @mock.body.should be_kind_of(StringIO)
    @mock.body.read.should == ''
  end 
end

describe Merb::Test::FakeRequest, ".with(path, options = {})" do
  before(:each) do
    @mock = Merb::Test::FakeRequest.with('/foo?bar=baz') 
  end
  
  it "should set REQUEST_URI to path" do
    @mock['REQUEST_URI'].should == '/foo?bar=baz'
  end
  
  it "should set PATH_INFO to path without query string" do
    @mock['PATH_INFO'].should == '/foo'
  end
  
  it "should pass other options through to new" do
    @mock = Merb::Test::FakeRequest.with('/foo?bar=baz', :http_accept => 'cash/money')
    @mock['HTTP_ACCEPT'].should == 'cash/money' 
  end
end

describe Merb::Test::FakeRequest, ".post_body=(post)" do
  it "should wrap post param in new StringIO" do
    @mock = Merb::Test::FakeRequest.new
    @mock.post_body = "hello world"
    @mock.body.should be_kind_of(StringIO)
    @mock.body.read.should == "hello world"
  end
end

describe Merb::Test::FakeRequest, "[](key)" do
  it "should return the key from @env" do
    @mock = Merb::Test::FakeRequest.new(:http_accept => 'cash/money')
    @mock['HTTP_ACCEPT'].should == 'cash/money' 
  end
end

describe Merb::Test::FakeRequest, "[]=(key, value)" do
  it "should set key in @env to value" do
    @mock = Merb::Test::FakeRequest.new(:http_accept => 'cash/money')
    @mock['HTTP_ACCEPT'] = 'also/credit_card'
    @mock['HTTP_ACCEPT'].should == 'also/credit_card'     
  end
end