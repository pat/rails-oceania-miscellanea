require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::AbstractController do
  
  before(:all) do
    @abc = Merb::AbstractController
    @template = "/my/template/path/file.html.erb"
    @key = "/my/template/path/file.html"
  end
  
  before(:each) do 
    @abc.reset_template_path_cache!
  end
  
  after(:all) do
    Merb::Server.load_controller_template_path_cache
    Merb::Server.load_erubis_inline_helpers    
  end
  
  it "should add a template path" do
    @abc.add_path_to_template_cache(@template)
    @abc._template_path_cache.should include(@key)
    @abc._template_path_cache[@key].should == @template
  end
  
  it "should reset the template_path_cache" do
    @abc.add_path_to_template_cache(@template)
    @abc._template_path_cache.should_not be_empty
    @abc.reset_template_path_cache!
    @abc._template_path_cache.should be_empty
  end
  
  it "should return false if the template is the wrong format when adding" do
    @abc.add_path_to_template_cache("/my/path/to/template.rhtml").should == false
    @abc._template_path_cache.should_not include( "/my/path/to/template.rhtml")
  end
  
end