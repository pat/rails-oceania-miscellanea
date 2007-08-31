require "spec/spec_helper"

describe "Conditional Action Caching" do
  before :all do
    FileUtils.mkdir_p(FILE_STORE_PATH)
    ActionController::Routing::Routes.draw do |map|
      map.resources :conditional_actions
    end
  end
  
  before :each do
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
    @controller   = ConditionalActionsController.new
    @request.host = 'hostname.com'
    @controller.expire_fragment(/hostname.com/)
  end
  
  after :all do
    FileUtils.rm_r(FILE_STORE_PATH)
  end
  
  it "should cache when there's no condition supplied" do
    get :index
    @request.should have_cache
  end
  
  it "should cache when the condition is set to nil" do
    get :show, :id => 1
    @request.should have_cache
  end
  
  it "should cache when the condition is set to a symbol pointer to a method that returns true" do
    @controller.will_cache = true
    get :new
    @request.should have_cache
  end
  
  it "should not cache when the condition is set to a symbol pointer to a method that returns false" do
    @controller.will_cache = false
    get :new
    @request.should_not have_cache
  end
  
  it "should cache when the condition is set to a Proc that returns true" do
    @controller.will_cache = true
    get :edit, :id => 1
    @request.should have_cache
  end
  
  it "should not cache when the condition is set to a Proc that returns false" do
    @controller.will_cache = false
    get :edit, :id => 1
    @request.should_not have_cache
  end
  
  it "should raise ArgumentErrors when the condition is not a symbol or Proc" do
    post :create
    @response.body.include?('ArgumentError').should == true
    put :update, :id => 1
    @response.body.include?('ArgumentError').should == true
    delete :destroy, :id => 1
    @response.body.include?('ArgumentError').should == true
  end
end

ActionController::Caching::Actions::ActionCacheFilter.send(:include,
  ConditionalActionCaching)

class ConditionalActionsController < ActionController::Base
  attr_accessor :will_cache
  
  caches_action :index
  def index
    render :text => "index"
  end

  caches_action :show, :if => nil
  def show
    render :text => "show #{params[:id]}"
  end

  caches_action :new, :if => :will_cache
  def new
    render :text => "new"
  end
  
  caches_action :edit, :if => Proc.new { self.will_cache }
  def edit
    render :text => "edit #{params[:id]}"
  end
  
  caches_action :create, :if => 1
  def create
    render :text => "create"
  end
  
  caches_action :update, :if => "a"
  def update
    render :text => "update #{params[:id]}"
  end
  
  caches_action :destroy, :if => Time.now
  def destroy
    render :text => "destroy #{params[:id]}"
  end
end