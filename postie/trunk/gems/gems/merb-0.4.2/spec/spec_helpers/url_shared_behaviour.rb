describe "class with general url generation", :shared => true do
  
  before(:all) do
    Merb::Router.prepare do |r|
      @resource_routes = r.resources(:blogs)
      r.resources(:gardens) do |gardens|
        @nested_resource = gardens.resources :flowers
      end
      @test_route = r.match("/the/:place/:goes/here").to(:controller => "Test", :action => "show").name(:test)
      @default_route = r.default_routes
    end
  end


  it "should generate a url from a route using a hash" do
    c = new_url_controller(@test_route, :place => "1")
    c.url_from_route(@test_route, :goes => "g").should == "/the/1/g/here"
  end
  
  it "should generate a url from a route using an object" do
    c = new_url_controller(@test_route, :place => "2")
    obj = OpenStruct.new(:goes => "elsewhere")
    c.url_from_route(@test_route, obj).should == "/the/2/elsewhere/here"
  end
  
  it "should generate a url and tack extra params on as a query string" do
    c = new_url_controller(@test_route, :place => "1")
    c.url_from_route(@test_route, :goes => "g", :page => 2).should == "/the/1/g/here?page=2"
  end
  
  it "should generate a url directly from a hash using the current route as a default" do
    c = new_url_controller(@test_route, :goes => "swimmingly")
    c.url(:place => "provo").should == "/the/provo/swimmingly/here"
  end
  
  it "should generate a default route url with just :controller" do
    c = new_url_controller(@default_route)
    c.url(:controller => "welcome").should == "/welcome"
  end
  
  it 'should generate urls from nested resources' do
    c = new_url_controller(@nested_resource, :garden => 5)
    c.url(:flower, :garden_id => 1, :id => 3).should == "/gardens/1/flowers/3"
  end
  
  # it "should generate a default route url with an extra param" do
  #   c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
  #   c.url(:controller => :current, :monkey => "quux").should == "/foo/bar?monkey=quux"
  # end
  
  it "should generate a default route url with all options" do
    c = new_url_controller(@default_route, :controller => "foo", :action => "bar")
    c.url(:controller => "foo", :action => "bar", :id => "baz", :format => :js, :monkey => "quux").should == "/foo/bar/baz.js?monkey=quux"
  end
  
  it "should handle an object as the second arg" do
    c = new_url_controller(@resource_routes, :controller => "blogs", :action => "show")
    blog = mock("blog")
    blog.should_receive(:id).once.and_return(7)
    url = c.url(:blog, blog)
    url.should == "/blogs/7"
  end
  
  it "should point to /blogs/:blog_id if @blog is not new_record" do
    c = new_url_controller(@resource_routes, :controller => "blogs", :action => "index")
    blog = mock("blog")
    blog.should_receive(:id).once.and_return(7)
    blog.should_receive(:new_record?).once.and_return(false)
    url = c.url(:blog, blog)
    url.should == "/blogs/7"
  end
  
  it "should point to /blogs/ if @blog is new_record" do
    c = new_url_controller(@resource_routes, :controller => "blogs", :action => "index")
    blog = mock("blog")
    blog.should_receive(:new_record?).once.and_return(true)
    url = c.url(:blog, blog)
    url.should == "/blogs/"
  end
end

describe "non routeable controller with url mixin", :shared => true do
  
  before(:all) do
    Merb::Router.prepare do |r|
      @resource_routes = r.resources(:blogs)
      r.resources(:gardens) do |gardens|
        @nested_resource = gardens.resources :flowers
      end
      @test_route = r.match("/the/:place/:goes/here").to(:controller => "Test", :action => "show").name(:test)
      @default_route = r.default_routes
    end
  end
  
  it "should route when given a controller and an action" do
    c = new_url_controller(@default_route, :controller => "blah")
    the_url = c.url(:controller => "foo", :action => "bar")
    the_url.should == "/foo/bar"
  end
  
  it "should generate a route when only a controller is given" do
    c = new_url_controller(@default_route, :controller => "blah")
    the_url = c.url(:controller => "foo")
    the_url.should == "/foo"
  end
  
  it "should generate a route with controller action and extra options" do
    c = new_url_controller(@default_route, :controller => "blah")
    the_url = c.url(:controller => "foo", :action => "bar", :cool => "false")
    the_url.should == "/foo/bar?cool=false"
  end  
end
