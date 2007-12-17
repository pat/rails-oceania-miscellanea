require File.dirname(__FILE__) + '/../spec_helper'

class TestFiltersController < Merb::Controller
  
  before :filter1
  before :will_halt, :only => :four
  
  before :overwrite_before_filter, :only => :two
  after  :overwrite_after_filter, :exclude => :four
  
  after  :after_will_be_skipped
  before :before_will_be_skipped

  before Proc.new {|c| c.one }, :exclude => [:one, :three, :uses_params]
  after  Proc.new {|c| c.five }, :exclude => [:one, :three, :uses_params]  
  after  :filter2
  before :modifies_param, :only => :uses_params
  after  :restores_param, :only => :uses_params

  before :overwrite_before_filter, :only => :three
  after  :overwrite_after_filter, :exclude => [:one, :two, :uses_param]

  skip_before :before_will_be_skipped
  skip_after  :after_will_be_skipped
  
  # filters
  
  def will_halt
    throw :halt
  end
  
  def filters_halted
    "Filters Halted"
  end
  
  def modifies_param 
    params[:the_param] ||= ''
    params[:the_param_original] = params[:the_param]
    params[:the_param] += ' is modified'
  end
  
  def restores_param
    params[:the_param] = params[:the_param_original] + ' is restored'
    @used_params = params[:the_param]
  end
  
  def filter1
    @filter1='called'
  end
  
  def filter2
    @filter2='called'
  end
  
  def before_will_be_skipped
    @before_skip='called'
  end
  
  def after_will_be_skipped
    @after_skip='called'
  end
  
  def overwrite_before_filter
    @overwrite_before_filter='called'
  end
  
  def overwrite_after_filter
    @overwrite_after_filter='called'    
  end
  
  # actions
  
  def one
    session.data.should == {}
    @one = 'one'
  end
  
  def two
    @two = 'two'
  end
  
  def three
    @three = 'three'
  end
  
  def four
    @four = 'four'
  end
  
  def five
    @five = 'five'
  end
  
  def uses_params
    @uses_params = params[:the_param]
  end
  
end

class TestDefaultFiltersHalted < Merb::Controller
  before :will_halt
  
  def will_halt
    throw :halt
  end
  
  def one
  end
  
end

class TestPrivateActions < Merb::Controller
  
  protected
  def notcallable1
    "notcallable"
  end
  
  private
  def notcallable2
    "notcallable"
  end
  
end

describe "Dispatch and before/after filters" do
  
  def call_filter_action(action, extra_params = {})
    @c = new_controller( action, TestFiltersController, extra_params )
    @c.dispatch(action)
  end

  before :each do
    request = Merb::Test::FakeRequest.new
    @status, @response, @headers = 200, request.body, {'Content-Type' =>'text/html'}
    @request, @cookies = request, {}
  end
  
  it "should not allow calling protected actions" do
    c = new_controller( 'notcallable1', TestPrivateActions )
    lambda {c.dispatch(:notcallable1)}.should raise_error( Merb::ControllerExceptions::ActionNotFound)
  end  
  
  it "should not allow calling private actions" do
    c = new_controller( 'notcallable2', TestPrivateActions )
    lambda {c.dispatch(:notcallable2)}.should raise_error( Merb::ControllerExceptions::ActionNotFound)
  end

  it "should call a :symbol before and after filter" do
    c = new_controller( 'one', TestFiltersController )
    c.dispatch(:one)
    c.body.should == 'one'
    c.instance_variable_get('@one').should == 'one' 
    c.instance_variable_get('@two').should == nil
    c.instance_variable_get('@three').should == nil 
    c.instance_variable_get('@filter1').should == 'called'         
  end
  
  it "should be able to see instance variables" do
    call_filter_action "one"
    @c.cookies.should be_is_a(Hash) 
    @c.session.data.should == {}
    @c.response.read.should == ""
    @c.instance_variable_get("@filter1").should eql( 'called')
    @c.instance_variable_get("@one").should eql( 'one')
  end
  
  it "should ignore actions specified by :exclude" do
    call_filter_action "three"
    @c.instance_variable_get("@one").should be_nil
    @c.instance_variable_get("@five").should be_nil    
  end
  
  it "should be able to see params in the before filter" do
    call_filter_action "uses_params", :the_param => 'the param'
    @c.instance_variable_get("@uses_params").should eql( 'the param is modified')
  end

  it "should be able to see params in the after filter" do
    call_filter_action "uses_params", :the_param => 'the param'
    @c.instance_variable_get("@used_params").should eql( 'the param is restored')
  end
  
  it "should call a Proc before and after filter" do
    c = new_controller( 'two', TestFiltersController )
    c.dispatch(:two)
    c.body.should == 'two'
    c.instance_variable_get('@one').should == 'one'
    c.instance_variable_get('@two').should == 'two'
    c.instance_variable_get('@three').should == nil 
    c.instance_variable_get('@five').should == 'five'
  end
  
  it "should call filters_halted when throw :halt" do
    c = new_controller( 'four', TestFiltersController )
    c.dispatch(:four)
    c.body.should == "Filters Halted"
    c.instance_variable_get('@one').should == nil
    c.instance_variable_get('@two').should == nil
    c.instance_variable_get('@three').should == nil 
    c.instance_variable_get('@filter1').should == 'called' 
  end
  
  it "should have a default filter halted page" do
    c = new_controller( 'one', TestFiltersController )
    c.dispatch(:one)
  end
  
  it "should not allow both :only and :exclude" do
    ["before", "after"].each do |filter_type|
      lambda { TestFiltersController.send(filter_type, :x, :only => :foo, :exclude => :bar) }.should raise_error(ArgumentError)
    end
  end
  
  it "should not allow a filter that is not a symbol, string, or proc" do
    ["before", "after"].each do |filter_type|    
      lambda { TestFiltersController.send(filter_type, []) }.should raise_error(ArgumentError)
    end
  end
  
  it "should be overwritten by a subsequent call with the same filter" do
    c = new_controller( 'two', TestFiltersController )
    c.dispatch(:two)
    c.body.should == 'two'
    c.instance_variable_get('@overwrite_before_filter').should == nil
    c.instance_variable_get('@overwrite_after_filter').should == nil    
    
    c = new_controller( 'three', TestFiltersController )
    c.dispatch(:three)
    c.body.should == 'three'
    c.instance_variable_get('@overwrite_before_filter').should == 'called'
    c.instance_variable_get('@overwrite_after_filter').should == 'called'
  end
  
  it "should not run if skipped" do
    c = new_controller( 'one', TestFiltersController )
    c.dispatch(:one)
    c.body.should == 'one'
    c.instance_variable_get('@one').should == 'one' 
    c.instance_variable_get('@two').should == nil
    c.instance_variable_get('@three').should == nil 

    c.instance_variable_get('@before_skip').should == nil
    c.instance_variable_get('@after_skip').should == nil    
  end
  
  it "should not allow skipping a filter that is not a symbol or string" do
    ["before", "after"].each do |filter_type|    
      lambda { TestFiltersController.send('skip_'+filter_type, Proc.new{|c|puts c}) }.should raise_error(ArgumentError)
    end
  end

end