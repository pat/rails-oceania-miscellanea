require "spec/spec_helper"

describe "Conditional Fragment Caching in the controller" do  
  before :all do
    ActionController::Routing::Routes.draw do |map|
      map.resources :conditional_fragments
    end
  end
  
  before :each do
    @controller   = ConditionalFragmentsController.new
    @controller.expire_fragment(/hostname.com/)
  end

  it "should allow access to the conditional_cache helper" do
    ActionView::Helpers::CacheHelper.instance_methods.include?("conditional_cache").should == true
  end
  
  it "should allow access to conditional_read_fragment" do
    ActionController::Base.instance_methods.include?("conditional_read_fragment").should == true
    @controller.methods.include?("conditional_read_fragment").should == true
  end
  
  it "shouldn't generate a fragment when the condition is false" do
    @controller.will_cache = false
    get :show, :id => 1
    @request.should_not be_cached
  end
  
  it "should generate a fragment when the condition is true" do
    @controller.will_cache = true
    get :show, :id => 1
    @request.should be_cached
  end
  
  it "shouldn't return nil from conditional_read_fragment if a fragment exists and the condition is true" do
    @controller.will_cache = true
    get :show, :id => 1 # create cache
    @controller.inner_code.should == true
    get :show, :id => 1 # read cache
    @controller.inner_code.should == false
  end
  
  it "should return nil from conditional_read_fragment if a fragment exists and the condition is false" do
    @controller.will_cache = false
    get :show, :id => 1 # don't create cache
    @controller.inner_code.should == true
    get :show, :id => 1 # still doesn't create cache
    @controller.inner_code.should == true
  end
end

ActionView::Helpers::CacheHelper.send(:include,
  ConditionalFragmentCaching::ActionView)
ActionController::Base.send(:include,
  ConditionalFragmentCaching::ActionController)
  
class ConditionalFragmentsController < ActionController::Base
  attr_accessor :will_cache
  attr_accessor :inner_code
  
  append_view_path File.join(File.dirname(__FILE__))

  def show
    self.inner_code = !conditional_read_fragment(self.will_cache) 
  end
end