require "spec/spec_helper"

ActionController::Caching::Actions::ActionCacheFilter.send(:include,
  ConditionalActionCaching)

class ConditionalActionsController < ActionController::Base
  caches_action :index
  def index
    render :text => "index"
  end

  def show
    render :text => "show #{params[:id]}"
  end

  def new
    render :text => "new"
  end
  
  def create
    render :text => "create"
  end
  
  def edit
    render :text => "edit #{params[:id]}"
  end
  
  def update
    render :text => "update #{params[:id]}"
  end
  
  def destroy
    render :text => "destroy #{params[:id]}"
  end
end

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
  
  it "should cache when there's no condition supplied" do
    get :index
    @request.should have_cache
  end
end