require 'ostruct'
require File.dirname(__FILE__) + '/../spec_helper'

describe "Merb::Controller" do
  
  # not sure what this tests
  # it "should instantiate" do
  #   c = new_controller
  #   @request.env.should == c.request.env
  # end
  
  it "should have a default layout of application.rhtml" do
    c = new_controller
    c._layout.should == :application
  end
  
  it "should have a spec helper to dispatch that skips the router" do
    Merb::Router.should_not_receive(:match)
    dispatch_to(Bar, :foo, :id => "1") do |controller|
      controller.should_receive(:foo).with("1")
    end
  end
  
end

describe Merb::Controller, "url generator tests" do
  
  it_should_behave_like "class with general url generation"
  
  def new_url_controller(route, params = {:action => 'show', :controller => 'Test'})
    request = OpenStruct.new
    request.route = route
    request.params = params
    response = OpenStruct.new
    response.read = ""
    
    Merb::Controller.build(request, response)
  end

  it "should generate a default route url with just :action" do
    c = new_url_controller(@default_route, :controller => "foo")
    c.url(:action => "baz").should == "/foo/baz"
  end
  
  it "should generate a default route url with just :id" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:id => "23").should == "/foo/bar/23"
  end

  it "should generate a default route url with an extra param" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:controller => :current, :monkey => "quux").should == "/foo/bar?monkey=quux"
  end

  it "should generate a default route url with extra params" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    url = c.url(:controller => :current, :monkey => "quux", :cow => "moo")
    url.should match(%r{/foo/bar?.*monkey=quux})
    url.should match(%r{/foo/bar?.*cow=moo})
  end

  it "should generate a default route url with extra params and an array" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:controller => :current, :monkey => [1,2]).should == "/foo/bar?monkey[]=1&monkey[]=2"
  end
  
  it "should generate a default route url with extra params and a hash" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:controller => :current, :animals => {:cow => "moo"}).should == "/foo/bar?animals[cow]=moo"
  end

  it "should generate a default route url with :action and :format" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:action => :recent, :format => :txt).should == "/foo/recent.txt"
  end  
  
  it "should handle nested nested and more nested hashes and arrays" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    url = c.url(:controller => :current, :user => {:filter => {:name => "quux*"}, :order => ["name"]})
    url.should match(%r{/foo/bar?.*user\[filter\]\[name\]=quux%2A})
    url.should match(%r{/foo/bar?.*user\[order\]\[\]=name})
  end
end

describe "Controller", "redirect spec helpers" do
  class Redirector < Merb::Controller
    def index
      redirect("/foo")
    end
    def show
    end
  end
  
  before(:each) do
    @controller = Redirector.build(fake_request)
  end
  
  it "should be able to match redirects" do
    @controller.dispatch('index')
    @controller.status.should be_redirect
    @controller.should redirect
    @controller.should redirect_to("/foo")
  end
  
  it "should be able to negative match redirects" do
    @controller.dispatch('show')
    @controller.status.should_not be_redirect
    @controller.should_not redirect
    @controller.should_not redirect_to("/foo")
  end
end
