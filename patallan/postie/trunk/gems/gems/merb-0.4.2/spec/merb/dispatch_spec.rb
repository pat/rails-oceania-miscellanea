require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/controllers/dispatch_spec_controllers'

$TESTING = true

describe Merb::Dispatcher do

  before(:all) do
    Merb::Server.config[:allow_reloading] = false
    Merb::Router.prepare do |r|
      r.resource :icon
      r.resources :posts, :member => {:stats => [:get, :put]}, 
                          :collection => {:filter => [:get]} do |post|
        post.resources :comments,  :member => {:stats => [:get, :put]}
        post.resource :profile
      end  
      r.resources :as do |a|
        a.resources :bs do |b|
          b.resources :cs
        end  
      end
      r.match("/admin") do |admin|
        admin.resources :tags
      end
      r.default_routes
    end
  end
  
  it "should not overwrite url params with query string params" do
    controller, action = request(:get, '/foo/bar/42?id=24')
    controller.class.should == Foo
    action.should == "bar"
    controller.params[:id].should == '42'
  end  
  
  it "should not allow private and protected methods to be called" do
    controller, action = request(:get, '/foo/call_filters')
    controller.status.should == Merb::ControllerExceptions::ActionNotFound::STATUS
  end  
  
  it "should handle request: GET /foo/bar and return Foo#bar" do
    controller, action = request(:get, '/foo/bar')
    e = controller.params[:exception]
    controller.class.should == Foo
    action.should == "bar"
    controller.body.should == "bar"
  end
  
  it "should handle request: GET /foo/bar/1.xml and return Foo#bar format xml" do
    controller, action = request(:get, '/foo/bar/1.xml')
    controller.class.should == Foo
    controller.params[:format].should == 'xml'
    action.should == "bar"
    controller.body.should == "bar"
  end
  
  it "should handle request: GET /foo/bar.xml and return Foo#bar format xml" do
    controller, action = request(:get, '/foo/bar.xml')
    controller.class.should == Foo
    controller.params[:format].should == 'xml'
    action.should == "bar"
    controller.body.should == "bar"
  end
  
  it "should handle request: GET /foo.xml and return Foo#index format xml" do
    controller, action = request(:get, '/foo.xml')
    controller.class.should == Foo
    controller.params[:format].should == 'xml'
    action.should == "index"
    controller.body.should == "index"
  end
  
  it "should handle request: GET /foo and return Foo#index" do
    controller, action = request(:get, '/foo')
    controller.class.should == Foo
    action.should == "index"
    controller.body.should == "index"
  end
  
  it "should handle request: GET /icon and return Icon#show" do
    controller, action = request(:get, '/icon')
    controller.class.should == Icon
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /icon.xml and return Icon#show format xml" do
    controller, action = request(:get, '/icon.xml')
    controller.class.should == Icon
    action.should == "show"
    controller.params[:format].should == 'xml'
    controller.body.should == :show
  end
  
  it "should handle request: GET /icon/new and return Icon#new" do
    controller, action = request(:get, '/icon/new')
    controller.class.should == Icon
    action.should == "new"
    controller.body.should == :new
  end
  
  it "should handle request: GET /icon;edit and return Icon#edit" do
    controller, action = request(:get, '/icon;edit')
    controller.class.should == Icon
    action.should == "edit"
    controller.body.should == :edit
  end
  
  it "should handle request: GET /icon/edit and return Icon#edit" do
    controller, action = request(:get, '/icon/edit')
    controller.class.should == Icon
    action.should == "edit"
    controller.body.should == :edit
  end
  
  it "should handle request: POST /icon and return Icon#create" do
    controller, action = request(:post, '/icon')
    controller.class.should == Icon
    action.should == "create"
    controller.body.should == :create
  end
  
  it "should handle request: PUT /icon and return Icon#update" do
    controller, action = request(:put, '/icon')
    controller.class.should == Icon
    action.should == "update"
    controller.body.should == :update
  end
  
  it "should handle request: DELETE /icon and return Icon#destroy" do
    controller, action = request(:delete, '/icon')
    controller.class.should == Icon
    action.should == "destroy"
    controller.body.should == :destroy
  end
  
  it "should handle request: GET /admin/tags and return Tags#index" do
    controller, action = request(:get, '/admin/tags')
    controller.class.should == Tags
    action.should == "index"
    controller.body.should == :index
  end
  
  it "should handle request: GET /admin/tags.xml and return Tags#index format xml" do
    controller, action = request(:get, '/admin/tags.xml')
    controller.class.should == Tags
    action.should == "index"
    controller.params[:format].should == 'xml'
    controller.body.should == :index
  end

  it "should handle request: GET /posts and return Posts#index" do
    controller, action = request(:get, '/posts')
    controller.class.should == Posts
    action.should == "index"
    controller.body.should == :index
  end
  
  it "should handle request: GET /posts;filter and return Posts#filter" do
    controller, action = request(:get, '/posts;filter')
    controller.class.should == Posts
    action.should == "filter"
    controller.body.should == :filter
  end
  
  it "should handle request: GET /posts/filter and return Posts#filter" do
    controller, action = request(:get, '/posts/filter')
    controller.class.should == Posts
    action.should == "filter"
    controller.body.should == :filter
  end
  
  it "should handle request: GET /posts/1/comments and return Comments#index with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments')
    controller.class.should == Comments
    action.should == "index"
    controller.body.should == :index
  end
  
  it "should handle request: GET /posts/1/profile and return Profile#show with post_id == 1" do
    controller, action = request(:get, '/posts/1/profile')
    controller.class.should == Profile
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts/1/profile.xml and return Profile#show with post_id == 1" do
    controller, action = request(:get, '/posts/1/profile.xml')
    controller.class.should == Profile
    controller.params[:format].should == 'xml'
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts.xml and return Posts#index format xml" do
    controller, action = request(:get, '/posts.xml')
    controller.class.should == Posts
    controller.params[:format].should == 'xml'
    action.should == "index"
    controller.body.should == :index
  end
  
  it "should handle request: GET /posts/1 and return Posts#show" do
    controller, action = request(:get, '/posts/1')
    controller.class.should == Posts
    action.should == "show"
    controller.params[:id].should == '1'
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts/1/comments/1 and return Comments#show with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /as/1/bs/1 and return Bs#show with as_id == 1 & id == 1" do
    controller, action = request(:get, '/as/1/bs/1')
    controller.class.should == Bs
    controller.params[:id].should == '1'
    controller.params[:a_id].should == '1'
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /as/1/bs/1/cs and return Cs#show with a_id == 1 & b_id == 1" do
    controller, action = request(:get, '/as/1/bs/1/cs')
    controller.class.should == Cs
    controller.params[:b_id].should == '1'
    controller.params[:a_id].should == '1'
    action.should == "index"
    controller.body.should == :index
  end
  
  it "should handle request: GET /as/1/bs/1/cs/1  and return Bs#show with as_id == 1 & b_id == 1 & id == 1" do
    controller, action = request(:get, '/as/1/bs/1/cs/1')
    controller.class.should == Cs
    controller.params[:id].should == '1'
    controller.params[:a_id].should == '1'
    controller.params[:b_id].should == '1'
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts/1.xml and return Posts#show format xml" do
    controller, action = request(:get, '/posts/1.xml')
    controller.class.should == Posts
    controller.params[:format].should == 'xml'
    action.should == "show"
    controller.params[:id].should == '1'
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts/1/comments/1.xml and return Comments#show with post_id == 1 and format xml" do
    controller, action = request(:get, '/posts/1/comments/1.xml')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:format].should == 'xml'
    controller.params[:post_id].should == '1'
    action.should == "show"
    controller.body.should == :show
  end
  
  it "should handle request: GET /posts/new and return Posts#new" do
    controller, action = request(:get, '/posts/new')
    controller.class.should == Posts
    action.should == "new"
    controller.body.should == :new
  end
  
  it "should handle request: GET /posts/1/comments/new and return Comments#new with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/new')
    controller.class.should == Comments
    action.should == "new"
    controller.body.should == :new
  end
  
  it "should handle request: GET /posts/1;edit and return Posts#edit" do
    controller, action = request(:get, '/posts/1;edit')
    controller.class.should == Posts
    action.should == "edit"
    controller.params[:id].should == '1'
    controller.body.should == :edit
  end
  it "should handle request: GET /posts/1/edit and return Posts#edit" do
    controller, action = request(:get, '/posts/1/edit')
    controller.class.should == Posts
    action.should == "edit"
    controller.params[:id].should == '1'
    controller.body.should == :edit
  end
  
  it "should handle request: GET /posts/1/comments/1;edit and return Comments#edit with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1;edit')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    action.should == "edit"
    controller.body.should == :edit
  end
  
  it "should handle request: GET /posts/1/comments/1/edit and return Comments#edit with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1/edit')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    action.should == "edit"
    controller.body.should == :edit
  end
  
  it "should handle request: POST /posts and return Posts#create" do    
    controller, action = request(:post, '/posts')
    controller.class.should == Posts
    action.should == "create"
    controller.body.should == :create
  end
  
  it "should handle request: POST /posts/1/comments and return Comments#create  with post_id == 1" do    
    controller, action = request(:post, '/posts/1/comments')
    controller.class.should == Comments
    action.should == "create"
    controller.body.should == :create
  end
  
  it "should handle request: POST /posts/1/comments.xml and return Comments#create  with post_id == 1 and format xml" do    
    controller, action = request(:post, '/posts/1/comments.xml')
    controller.class.should == Comments
    controller.params[:format].should == 'xml'
    action.should == "create"
    controller.body.should == :create
  end
  
  
  it "should handle request: POST /posts.xml and return Posts#create format xml" do    
    controller, action = request(:post, '/posts.xml')
    controller.class.should == Posts
    controller.params[:format].should == 'xml'
    action.should == "create"
    controller.body.should == :create
  end
  
  it "should handle request: PUT /posts/1 and return Posts#update" do
    controller, action = request(:put, '/posts/1')
    controller.class.should == Posts
    action.should == "update"
    controller.params[:id].should == '1'
    controller.body.should == :update
  end
  
  it "should handle request: PUT /posts/1/comments/1 and return Comments#update with post_id == 1" do
    controller, action = request(:put, '/posts/1/comments/1')
    controller.class.should == Comments
    action.should == "update"
    controller.params[:post_id].should == '1'
    controller.params[:id].should == '1'
    controller.body.should == :update
  end
  
  it "should handle request: PUT /posts/1.xml and return Posts#update format xml" do    
    controller, action = request(:put, '/posts/1.xml')
    controller.class.should == Posts
    controller.params[:format].should == 'xml'
    controller.params[:id].should == '1'
    action.should == "update"
    controller.body.should == :update
  end
  
  it "should handle request: PUT /posts/1/comments/1.xml and return Comments#update with post_id == 1 and format xml" do
    controller, action = request(:put, '/posts/1/comments/1.xml')
    controller.class.should == Comments
    action.should == "update"
    controller.params[:post_id].should == '1'
    controller.params[:format].should == 'xml'
    controller.params[:id].should == '1'
    controller.body.should == :update
  end
  
  it "should handle request: DELETE /posts/1 and return Posts#destroy" do
    controller, action = request(:delete, '/posts/1')
    controller.class.should == Posts
    controller.params[:id].should == '1'
    action.should == "destroy"
    controller.body.should == :destroy
  end
  
  it "should handle request: DELETE /posts/1/comments/1 and return Comments#destroy with post_id == 1" do
    controller, action = request(:delete, '/posts/1/comments/1')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    action.should == "destroy"
    controller.body.should == :destroy
  end
  
  it "should handle request: DELETE /posts/1.xml and return Posts#destroy format xml" do    
    controller, action = request(:delete, '/posts/1.xml')
    controller.class.should == Posts
    controller.params[:format].should == 'xml'
    controller.params[:id].should == '1'
    action.should == "destroy"
    controller.body.should == :destroy
  end
  
  it "should handle request: DELETE /posts/1/comments/1.xml and return Comments#destroy with post_id == 1" do
    controller, action = request(:delete, '/posts/1/comments/1.xml')
    controller.class.should == Comments
    controller.params[:id].should == '1'
    controller.params[:format].should == 'xml'
    controller.params[:post_id].should == '1'
    action.should == "destroy"
    controller.body.should == :destroy
  end
  
  it "should handle request: GET /posts/1;stats and return Posts#stats" do
    controller, action = request(:get, '/posts/1;stats')
    controller.class.should == Posts
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: GET /posts/1/stats and return Posts#stats" do
    controller, action = request(:get, '/posts/1/stats')
    controller.class.should == Posts
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: GET /posts/1/comments/1;stats and return Comments#stats with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1;stats')
    controller.class.should == Comments
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: GET /posts/1/comments/1/stats and return Comments#stats with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1/stats')
    controller.class.should == Comments
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: PUT /posts/1;stats and return Posts#stats" do
    controller, action = request(:put, '/posts/1;stats')
    controller.class.should == Posts
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: PUT /posts/1/comments/1;stats and return Comments#stats with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1;stats')
    controller.class.should == Comments
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    controller.body.should == :stats
  end
  
  it "should handle request: PUT /posts/1/comments/1/stats and return Comments#stats with post_id == 1" do
    controller, action = request(:get, '/posts/1/comments/1/stats')
    controller.class.should == Comments
    action.should == 'stats'
    controller.params[:id].should == '1'
    controller.params[:post_id].should == '1'
    controller.body.should == :stats
  end
  
  it "should show the custom error page" do
    controller, action = request(:get, '/foo/error')
    controller.body.should == "oh no!"
  end
  
  it "should show the a 404 error page" do
    controller, action = request(:get, '/foo/raise404')
    controller.status.should == Merb::ControllerExceptions::NotFound::STATUS
  end
  
  it "should not show the a 404 error page if you call with upcase url" do
    controller, action = request(:get, '/Posts/1')
    controller.status.should == Merb::ControllerExceptions::NotFound::STATUS
  end
  
  it "should not show the a 404 error page if you call with - in the controller name with no explicit route" do
    controller, action = request(:get, '/pos-ts/1')
    controller.status.should == Merb::ControllerExceptions::NotFound::STATUS
  end

  if defined?(ParseTreeArray)
    it "should support parameterized actions with required arguments" do
      controller, action = request(:get, '/bar/foo/1')
      controller.body.should == "1"
    end
    
    it "should support parameterized actions with required and optional arguments" do
      controller, action = request(:get, '/bar/bar?a=1&b=3')
      controller.body.should == "1 3"
    end
    
    it "should use optional arguments in parameters if they exist" do
      controller, action = request(:get, '/bar/bar?a=1')
      controller.body.should == "1 2"
    end
    
    it "should use optional arguments even if a later argument is provided" do
      controller, action = request(:get, '/bar/baz?a=1&c=5')
      controller.body.should == "1 2 5"
    end
  end


end