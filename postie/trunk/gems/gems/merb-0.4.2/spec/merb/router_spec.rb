require File.dirname(__FILE__) + '/../spec_helper'
require 'benchmark'
include Benchmark

require FIXTURES / 'models/router_spec_models'
$TESTING = true

# OpenStruct fails to return 'method' correctly, which we require for our Request object
class SimpleRequest < OpenStruct
  def method() @table[:method] end
end

describe Merb::Router::CachedProc do
  it "should register a regular expression" do
    regexp = /t.*e.*s.*t/
    cc = Merb::Router::CachedProc.new(regexp)
    Merb::Router::CachedProc[cc.index].cache.should == regexp
  end

  it "should register a proc" do
    testproc = proc { puts 'test' }
    cc = Merb::Router::CachedProc.new(testproc)
    Merb::Router::CachedProc[cc.index].cache.should == testproc
  end
  
  it "should return ruby code as an evaluatable string" do
    testproc = proc { 'test proc' }
    cc = Merb::Router::CachedProc.new(testproc)
    "#{cc}".should == "CachedProc[#{cc.index}].cache"
    eval("Merb::Router::#{cc}.call").should == "test proc"
  end
end

describe Merb::Router do
  it "should compile to an if / elsif statement" do
    lambda {
      Merb::Router.prepare do |r|
        r.match('/:controller/:action').to_resources(:controller => '/admin/:controller')
      end
      Merb::Router.compiled_statement.should match(/^\s*if/m)
    }.should_not raise_error
  end
  
  it "should match against requests" do
    Merb::Router.prepare do |r|
      r.match('/:controller/:action').to_resources(:controller => '/admin/:controller')
    end
    request = Merb::Test::FakeRequest.new(:request_uri => "/test/request")
    result = Merb::Router.match(request, {})
  end
  
  it "should be able to prepend routes to the @@routes list" do
    r1, r2 = nil, nil
    Merb::Router.prepare do |r|
      r1 = r.match('/:controller/:action').to(:controller => '/admin/:controller')
    end
    Merb::Router.prepend do |r|
      r2 = r.match('/:controller/:action').to(:controller => '/admin/:controller')
    end
    Merb::Router.routes[0].should == r2
    Merb::Router.routes[1].should == r1
  end
  
  it "should be able to append routes to the @@routes list" do
    r1, r2 = nil, nil
    Merb::Router.prepare do |r|
      r1 = r.match('/:controller/:action').to(:controller => '/admin/:controller')
    end
    Merb::Router.append do |r|
      r2 = r.match('/:controller/:action').to(:controller => '/admin/:controller')
    end
    Merb::Router.routes[0].should == r1
    Merb::Router.routes[1].should == r2
  end
  
  it "should have a spec helper to match routes" do
    Merb::Router.prepare{ |r| r.default_routes }
    with_route("/pages/show/1", "GET") do |params|
      params[:controller].should == "pages"
      params[:action].should == "show"
      params[:id].should == "1"
    end    
  end

  # it "should be fast" do
  #   Merb::Router.prepare do |r|
  #     r.resource :icon
  #     r.resources :posts, :member => {:stats => [:get, :put]}, 
  #                         :collection => {:filter => [:get]} do |post|
  #       post.resources :comments,  :member => {:stats => [:get, :put]}
  #       post.resource :profile
  #     end  
  #     r.resources :as do |a|
  #       a.resources :bs do |b|
  #         b.resources :cs
  #       end  
  #     end
  #     r.match("/admin") do |admin|
  #       admin.resources :tags
  #     end
  #     r.default_routes
  #   end
  #   request = Merb::Test::FakeRequest.new(:request_uri => "/test/request")
  #   
  #   bm(12) do |test|
  #     #                          user     system      total        real
  #     # with CachedCode        4.510000   0.050000   4.560000 (  5.244656)
  #     # with in-place regexps  2.130000   0.030000   2.160000 (  2.272443)
  #     test.report("with in-place regexps") do
  #       20_000.times do
  #         Merb::Router.match(request)
  #       end
  #     end
  #   end
  # end
end

describe Merb::Router, "when doing route matching with a big set of example routes" do
  require 'set'
  def should_only_have_keys(hash, *keys)
    Set.new(hash.keys).should == Set.new(keys)
  end
  
  before(:all) do
    Merb::Router.prepare do |r|
      # A simple route match, sends "/contact" to Info#contact
      # (i.e. the 'contact' method inside the 'Info' controller)
      r.match("/contact").
        to(:controller => "info", :action => "contact")
      
      # Use placeholders (e.g. :book_id) in the match, and they will be passed along to params
      r.match("/books/:book_id/:action").
        to(:controller => "books")
      
      # Use placeholders in the "to" results for more complicated routing, e.g. for modules
      r.match("/admin/:module/:controller/:action").
        to(:controller => ":module/:controller")
      r.match("/admin/:module/:controller/:action/:id").
        to(:controller => ":module/:controller")
      
      # Use a 'match' block to factor out repetitive 'match' parts
      r.match("/accounts") do |a|
        # The following will match "/accounts/overview" and route to Accounts#overview
        a.match("/overview").
          to(:controller => "accounts", :action => "overview")
        a.match("/:id/:action").
          to(:controller => "accounts")
        a.match("/:id/:action.:format").
          to(:controller => "accounts")
      end
      
      # Use a 'to' block to factor out repetitive 'to' parts
      r.to(:controller => "accounts") do |a|
        $r = a.match("/reports").
          to(:action => "reports") # maps to Accounts#reports
        
        a.match("/slideshow/:id").
          to(:action => "slideshow") # maps to Accounts#slideshow
      end
      
      # Use a regular expression as the path matcher.  Note that you must specify the
      # ^ (beginning of line) and $ (end of line) boundaries if you desire them.
      r.match(%r{^/movies/:id/movie-[a-z][a-zA-Z\-]+$}).
        to(:controller => "movies", :action => "search_engine_optimizer")
      
      # Use square-bracket notation to replace param results with captures from the path
      r.match(%r[^/movies/(\d+)-(\d+)-(\d+)$]).
        to(:controller => "movies", :movie_id => "[1][2][3]", :action => "show")

      # Use the second optional argument of 'match' to be more specific about the request;
      # in this case, only accept the POST method for the /movies/create action
      r.match("/movies/create", :method => "post").
        to(:controller => "movies", :action => "create")
      
      # Use variables from the 'match' as results sent to the controller in the params hash,
      # e.g. :user_agent[1] will be replaced with either 'MSIE' or 'Gecko' in the following case:
      r.match(%r[^/movies/(.+)], :user_agent => /(MSIE|Gecko)/).
        to(:controller => "movies", :title => "[1]", :action => "show", :agent => ":user_agent[1]")

      # The 'match' method can also be called without the path string or regexp.
      # In this example, direct all insecure traffic to a Insecure#index
      r.match(:protocol => "http://").
        to(:controller => "insecure", :action => "index")

      # Use anonymous placeholders in place of the ugly-looking pattern, /([^\/.,;?]+)/
      r.match("/::/users/::").
        to(:controller => "users", :action => "[2]", :id => "[1]")
      
      # Namespace can be used to specify the module
      r.match('/bar').to(:controller => 'bar', :namespace => 'foo')
      
      # Namespace can be used to provide path prefix
      r.match('/admin').to(:namespace => 'admin') do |foo|
        foo.match('/foo').to(:controller => 'foo')
      end
      r.match('/foo').to(:controller => 'foo')
        
      # Putting it all together, and adding the requirement that we use an "admin" prefix on the
      # host (e.g. admin.mysite.com), do some interesting stuff:
      r.match(:host => /^admin\b/).to(:namespace => 'admin') do |admin|
        admin.match(%r[/([A-Z]\w+)\+([A-Z]\w+)/::]).
          to(:controller => "users", :action => ":path[3]",
            :first_name => ":path[1]", :last_name => ":path[2]")
      end.to(:controller => "users", :action => "default")
      # Note that the last line above sends all traffic in the "admin" subdomain to the
      # Admin::Users#default action if no other route is matched.

      # Create a deferred route.  In this case, the decision of whether or not the route
      # is a match is made via the .xhr? call.  Note that it's ok to put the hash in a
      # conditional because if the "if" statement is false, ruby returns nil (i.e. no match).
      r.match(%r[^/deferred]).defer_to do |request, params|
        {:controller => "ajax", :action => "index"} if request.xhr?
      end
      
      # Use the placeholders in a the  deferred route
      r.match("/deferred/:action").defer_to do |request, params|
        params.merge(:controller => "deferred")
      end
    end
  end

  it "should connect '/contact' to Info#contact" do
    index, route = Merb::Router.match(SimpleRequest.new(:protocol => "http://", :path => '/contact'), {})
    route[:controller].should == "info"
    route[:action].should == "contact"
    should_only_have_keys(route, :controller, :action)
  end

  it "should use placeholders in the match and pass them along to the params" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/books/12/show'), {})
    route[:controller].should == "books"
    route[:action].should == "show"
    route[:book_id].should == "12"
    should_only_have_keys(route, :controller, :action, :book_id)
  end

  it "should allow placeholders to be used in the params to construct results from matches" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/admin/accounts/users/index'), {})
    route[:controller].should == "accounts/users"
    route[:action].should == "index"
    should_only_have_keys(route, :module, :controller, :action)
    
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/admin/payment/processors/edit/4'), {})
    route[:controller].should == "payment/processors"
    route[:action].should == "edit"
    route[:id].should == "4"
    should_only_have_keys(route, :module, :controller, :action, :id)
  end

  it "should allow 'match' to use a block to factor out repetitive parts, merging the path as it goes" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/accounts/overview'), {})
    route[:controller].should == "accounts"
    route[:action].should == "overview"
    should_only_have_keys(route, :controller, :action)
    
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/accounts/12/show.xml'), {})
    route[:controller].should == "accounts"
    route[:action].should == "show"
    route[:id].should == "12"
    route[:format].should == "xml"
    should_only_have_keys(route, :controller, :action, :id, :format)
  end
  
  it "should allow 'to' to use a block to factor out repetitive params" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/reports'), {})
    route[:controller].should == "accounts"
    route[:action].should == "reports"
    should_only_have_keys(route, :controller, :action)

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/slideshow/2'), {})
    route[:controller].should == "accounts"
    route[:action].should == "slideshow"
    route[:id].should == "2"
    should_only_have_keys(route, :controller, :action, :id)
  end
  
  it "should be able to use a regular expression instead of a string as the path-matcher" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/movies/5/movie-an-adventure-in-wonderland'), {})
    route[:controller].should == "movies"
    route[:action].should == "search_engine_optimizer"
    route[:id].should == "5"
    should_only_have_keys(route, :controller, :action, :id)
  end

  it "should be able to use square bracket notation to replace param results with captures from the path" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/movies/123-1-9999'), {})
    route[:controller].should == "movies"
    route[:action].should == "show"
    route[:movie_id].should == "12319999"
    should_only_have_keys(route, :controller, :action, :movie_id)
  end
  
  it "should only allow the POST method to '/movies/create'" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/movies/create', :method => "get"), {})
    route[:controller].should be_nil
    route[:action].should be_nil
    should_only_have_keys(route)

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/movies/create', :method => "post"), {})
    route[:controller].should == "movies"
    route[:action].should == "create"
    should_only_have_keys(route, :controller, :action)
  end

  it "should use variables from the 'match' as a result sent to the controller in the params hash" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/movies/harry-potter-3', :user_agent => "Internet Explorer (MSIE)"), {})
    route[:controller].should == "movies"
    route[:action].should == "show"
    route[:title].should == "harry-potter-3"
    route[:agent].should == "MSIE"
    should_only_have_keys(route, :controller, :action, :title, :agent)
  end
  
  it "should be able to match without the use of a path, sending all HTTP traffic to 'insecure' controller" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/visit', :protocol => "http://"), {})
    route[:controller].should == "insecure"
    route[:action].should == "index"
    should_only_have_keys(route, :controller, :action)
    
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/3/users/show', :protocol => "http://"), {})
    route[:controller].should == "insecure"
    route[:action].should == "index"
    should_only_have_keys(route, :controller, :action)
  end

  it "should use anonymous placeholders" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/5/users/show', :protocol => "https://"), {})
    route[:controller].should == "users"
    route[:action].should == "show"
    route[:id].should == "5"
    should_only_have_keys(route, :controller, :action, :id)
  end
  
  it "should use namespace" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/bar', :method => :get), {})
    route[:namespace].should == 'foo'
    route[:controller].should == 'bar'
    route[:action].should == 'index' 
    should_only_have_keys(route, :namespace, :controller, :action)   
  end
  
  it "should have namespace 'admin' if path is '/admin/foo'" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/admin/foo', :method => :get), {})
    route[:namespace].should == 'admin'
    route[:controller].should == 'foo'
    route[:action].should == 'index' 
    should_only_have_keys(route, :namespace, :controller, :action)   
  end
  
  it "should not have namespace if path is just '/foo'" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/foo', :method => :get), {})
    route[:controller].should == 'foo'
    route[:action].should == 'index' 
    should_only_have_keys(route, :controller, :action)   
  end
  
  it "should send all admin.* domains to the 'admin/users' controller, and 'default' action" do
    index, route = Merb::Router.match(SimpleRequest.new(:host => "admin.mysite.com", :path => '/welcome', :protocol => "https://"), {})
    route[:namespace].should == "admin"
    route[:controller].should == "users"
    route[:action].should == "default"
    should_only_have_keys(route, :namespace, :controller, :action)
    
    index, route = Merb::Router.match(SimpleRequest.new(:host => "admin.another-site.com", :path => '/go/somewhere/else', :protocol => "https://"), {})
    route[:namespace].should == "admin"
    route[:controller].should == "users"
    route[:action].should == "default"
    should_only_have_keys(route, :namespace, :controller, :action)
  end
  
  it "should decipher the first-name / last-name pairs on an admin.* domain" do
    index, route = Merb::Router.match(SimpleRequest.new(:host => "admin.mysite.com", :path => '/Duane+Johnson/edit', :protocol => "https://"), {})
    route[:namespace].should == "admin"
    route[:controller].should == "users"    
    route[:action].should == "edit"
    route[:first_name].should == "Duane"
    route[:last_name].should == "Johnson"
    should_only_have_keys(route, :namespace, :controller, :action, :first_name, :last_name)
  end
  
  it "should defer to the Ajax controller for xhr requests" do
    index, route = Merb::Router.match(SimpleRequest.new(:xhr? => true, :path => '/deferred/to/somewhere', :protocol => "https://"), {})
    route[:controller].should == "ajax"
    route[:action].should == "index"
    should_only_have_keys(route, :controller, :action)
  end
  
  it "should let a deferred block use the path's MatchData" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/deferred/elsewhere', :protocol => "https://"), {})
    route[:controller].should == "deferred"
    route[:action].should == "elsewhere"
    should_only_have_keys(route, :controller, :action)
  end
end

describe Merb::Router, "with a single resource, 'blogposts' with 'comments'" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :blogposts do |bposts|
        bposts.resources :comments
      end  
    end
  end

  it "should match /blogposts" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts', :method => :get), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'index'

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts', :method => :post), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'create'
  end

  it "should match /blogposts/new" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/new', :method => :get), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'new'
  end  

  it "should match /blogposts/1" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1', :method => :get), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'show'
    route[:id].should == '1'

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1', :method => :put), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'update'
    route[:id].should == '1'

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1', :method => :delete), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'destroy'
    route[:id].should == '1'
  end

  it "should match /blogposts/1;edit" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1;edit', :method => :get), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'edit'
    route[:id].should == '1'

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1;edit', :method => :put), {})
    route[:controller].should be_nil
    route[:action].should be_nil
  end

  it "should match /blogposts/1/edit" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1/edit', :method => :get), {})
    route[:controller].should == 'blogposts'
    route[:action].should == 'edit'
    route[:id].should == '1'

    index, route = Merb::Router.match(SimpleRequest.new(:path => '/blogposts/1/edit', :method => :put), {})
    route[:controller].should be_nil
    route[:action].should be_nil
  end

  it "should generate blogposts path" do
    Merb::Router.generate(:blogposts).should == '/blogposts'
  end

  it "should generate blogpost path" do
    Merb::Router.generate(:blogpost, {:id => 1}).should == '/blogposts/1'
    b = Blogposts.new
    Merb::Router.generate(:blogpost, b).should == '/blogposts/42'
    Merb::Router.generate(:blogpost, :id => b).should == '/blogposts/42'
  end

  it "should generate new_blogpost path" do
    Merb::Router.generate(:new_blogpost).should == '/blogposts/new'
  end

  it "should generate edit_blogpost path" do
    Merb::Router.generate(:edit_blogpost, {:id => 1}).should == '/blogposts/1/edit'
  end
    
  it "should generate comments path" do
    c = Comment.new     
    Merb::Router.generate(:comments, c).should == '/blogposts/42/comments'
  end
  
  it "should generate comment path" do
    c = Comment.new
    Merb::Router.generate(:comment, c).should == '/blogposts/42/comments/24'
  end
  
end


describe Merb::Router, "with resources using name_prefix, 'oranges' and 'ape'" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :oranges, :name_prefix => "florida_"
      r.resource :ape, :name_prefix => "grape_"
    end
  end
  
  it "should match /oranges" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/oranges', :method => :get), {})
    route[:controller].should == 'oranges'
    route[:action].should == 'index'
  end

  it "should generate florida_oranges path" do
    Merb::Router.generate(:florida_oranges).should == '/oranges'
  end

  it "should generate florida_orange path" do
    Merb::Router.generate(:florida_orange, {:id => 1}).should == '/oranges/1'
    b = Blogposts.new
    Merb::Router.generate(:florida_orange, b).should == '/oranges/42'
    Merb::Router.generate(:florida_orange, :id => b).should == '/oranges/42'
  end
  
  it "should generate new_florida_orange path" do
    Merb::Router.generate(:new_florida_orange).should == '/oranges/new'
  end
  
  it "should generate edit_florida_orange path" do
    Merb::Router.generate(:edit_florida_orange, {:id => 1}).should == '/oranges/1/edit'
  end  
  
  it "should match /ape" do
    index, route = Merb::Router.match(SimpleRequest.new(:path => '/ape', :method => :get), {})
    route[:controller].should == 'ape'
    route[:action].should == 'show'
  end

  it "should generate grape_ape path" do
    Merb::Router.generate(:grape_ape).should == '/ape'
  end

  it "should generate new_grape_ape path" do
    Merb::Router.generate(:new_grape_ape).should == '/ape/new'
  end
  
  it "should generate edit_grape_ape path" do
    Merb::Router.generate(:edit_grape_ape).should == '/ape/edit'
  end  
end

describe Merb::Router, "with resources using a collection action" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :flowers, :collection => { :random => [:get] }
    end
  end

  it "should generate random_flowers path" do
    Merb::Router.generate(:random_flowers).should == '/flowers/random'
  end
end

describe Merb::Router, "with resources using a member action" do
  before(:each) do
    Merb::Router.prepare do |r|
      r.resources :flowers, :member => { :pick => [:get] }
    end
  end

  it 'should generate pick_flower path' do
    Merb::Router.generate(:pick_flower, { :id => 1 }).should == '/flowers/1/pick'
  end
end

describe Merb::Router::Behavior do
  before(:all) do
    @behavior = Merb::Router::Behavior
  end
  
  it "should leave strings as strings and add ^...$ in the @conditions hash" do
    @behavior.new({:path => "/one/two"}).conditions[:path].should == "^/one/two$"
  end

  it "should replace special characters in strings with their escaped equivalents" do
    @behavior.new({:path => "test.xml"}).conditions[:path].should == "^test\\.xml$"
  end
  
  it "should convert symbols to strings and add ^...$ in the @conditions hash" do
    @behavior.new({:method => :get}).conditions[:method].should == "^get$"
  end
  
  it "should convert regular expressions to strings in the @conditions hash" do
    @behavior.new({:protocol => /https?/}).conditions[:protocol].should == "https?"
  end

  it "should deduce placeholders from the @conditions hash" do
    ph = @behavior.new({:path => "/:controller/:action"}).placeholders
    ph[:controller].should == [:path, 1]
    ph[:action].should == [:path, 2]
  end

  it "should deduce placeholders from the @conditions hash, even when they contain numbers" do
    ph = @behavior.new({:path => "/:part1/:part2"}).placeholders
    ph[:part1].should == [:path, 1]
    ph[:part2].should == [:path, 2]
  end

  it "should deduce placeholders within regular expressions that contain prefixed captures" do
    ph = @behavior.new({:path => %r[/(\d+)/:controller/:action]}).placeholders
    ph[:controller].should == [:path, 2]
    ph[:action].should == [:path, 3]

    ph = @behavior.new({:path => %r[/:controller/:action/(\d+)]}).placeholders
    ph[:controller].should == [:path, 1]
    ph[:action].should == [:path, 2]
  end
  
  it "should deduce placeholder positions in nested captures" do
    ph = @behavior.new({:path => %r[(/(\d+)/:controller)/:action]}).placeholders
    ph[:controller].should == [:path, 3]
    ph[:action].should == [:path, 4]

    ph = @behavior.new({:path => %r[/(\d+)/(:controller)/:action]}).placeholders
    ph[:controller].should == [:path, 3]
    ph[:action].should == [:path, 4]

    ph = @behavior.new({:path => %r[/(\d+)/:controller/(:action)]}).placeholders
    ph[:controller].should == [:path, 2]
    ph[:action].should == [:path, 4]

    ph = @behavior.new({:path => %r[(/(\d+)/(:controller/((:action))))]}).placeholders
    ph[:controller].should == [:path, 4]
    ph[:action].should == [:path, 7]
  end
  
  it "should replace any placeholders found within @conditions strings with segment regular expressions" do
    m = @behavior.new({:path => "/:my/:place:holders/:here"}).conditions
    m[:path].should == "^/([^/.,;?]+)/([^/.,;?]+)([^/.,;?]+)/([^/.,;?]+)$"
  end
  
  it "should set default values for params that came from placeholders" do
    p = @behavior.new({:path => "/:my/:place:holders/:here"}).params
    p[:my].should == ":my"
    p[:place].should == ":place"
    p[:holders].should == ":holders"
    p[:here].should == ":here"
  end
  
  it "should merge params with its ancestors" do
    b = @behavior.new({}, {:controller => "my_controller", :action => "index"})
    c = @behavior.new({}, {:action => "show"}, b)
    c.merged_params.should == {:controller => "my_controller", :action => "show"}
  end

  # it "should have a default action and controller for merged params" do
  #   a = @behavior.new
  #   a.merged_params.should == {:controller => "application", :action => "index"}
  # 
  #   b = @behavior.new({}, {:controller => "admin"})
  #   b.merged_params.should == {:controller => "admin", :action => "index"}
  # 
  #   c = @behavior.new({}, {:action => "show"})
  #   c.merged_params.should == {:controller => "application", :action => "show"}
  # end

  it "should merge conditions with its ancestors" do
    b = @behavior.new({:method => "get", :protocol => "http"})
    c = @behavior.new({:method => "put"}, {}, b)
    c.merged_conditions.should == {:method => "^put$", :protocol => "^http$"}
  end
  
  it "should merge placeholders with its ancestors" do
    b = @behavior.new({:method => "get", :protocol => ":ssl"}, {:action => ":method"})
    c = @behavior.new({:method => "put"}, {:action => ":ssl"}, b)
    c.merged_placeholders.should == {:ssl => [:protocol, 1]}
  end
  
  it "should add the number of path captures in the ancestors' paths to placeholders that hold a place for :path captures" do
    b = @behavior.new({:path => "/:controller/:action"})
    b.placeholders.should == {:controller => [:path, 1], :action => [:path, 2]}
    c = @behavior.new({:path => "/:id"}, {}, b)
    c.placeholders.should == {:id => [:path, 1]}
    
    c.merged_placeholders.should == {:controller => [:path, 1], :action => [:path, 2], :id => [:path, 3]}
  end
  
  it "should merge the :path differently than other @conditions keys -- it should concatenate" do
    b = @behavior.new({:method => "get", :protocol => "http"})
    c = @behavior.new({:path => "/test", :method => "put"}, {}, b)
    c.merged_conditions.should == {:method => "^put$", :protocol => "^http$", :path => "^/test$"}

    b = @behavior.new({:path => "/test", :method => "get", :protocol => "http"})
    c = @behavior.new({:method => "put"}, {}, b)
    c.merged_conditions.should == {:method => "^put$", :protocol => "^http$", :path => "^/test$"}

    b = @behavior.new({:path => "/admin", :method => "get", :protocol => "http"})
    c = @behavior.new({:path => "/test", :method => "put"}, {}, b)
    c.merged_conditions.should == {:method => "^put$", :protocol => "^http$", :path => "^/admin/test$"}
  end
  
  it "should be able to compile the @params to strings and request matches" do
    b = @behavior.new({:path => "/admin/:controller/:action", :method => "get"})
    cp = b.send(:compiled_params)
    cp[:controller].should == "path1"
    cp[:action].should == "path2"

    b = @behavior.new(
      {:path => "/admin/:controller/:action/:postfix", :method => "get"},
      {:controller => "/admin/:controller", :action => "neat_o_:action:postfix"})
    cp = b.send(:compiled_params)
    cp[:controller].should == "\"/admin/\" + path1"
    cp[:action].should == "\"neat_o_\" + path2 + path3"
  end

  it "should allow a bracketed number such as [3] to compile to path3" do
    b = @behavior.new(
      {:path => "/admin/:controller/:action/(.+)", :method => "get"},
      {:catchall => "[3]"})
    cp = b.send(:compiled_params)
    cp[:catchall].should == "path3"
  end

  it "should allow a backslash to escape an underscore in the compiled params" do
    b = @behavior.new(
      {:path => "/admin/:controller/:action", :method => "get"},
      {:action => "some_prefix_:action\\_other"})
    cp = b.send(:compiled_params)
    cp[:action].should == "\"some_prefix_\" + path2 + \"_other\""
  end
  
  it "should return a Route object containing compiled conditions and params when .to is called" do
    a = @behavior.new({:path => "/admin"})
    b = a.match("/:controller/:action", :method => "get")
    route = b.to(:controller => "/admin/:controller")
    route.conditions[:path].to_s.should == /^\/admin\/([^\/.,;?]+)\/([^\/.,;?]+)$/.to_s
    route.conditions[:method].should == /^get$/
    route.params.should == {:controller => "\"/admin/\" + path1", :action => "path2"}
  end
  
  it "should allow for conditional blocks using the 'defer_to' method" do
    b = @behavior.new({:path => "/admin"})
    route = b.defer_to { |request| {:controller => "late_bound", :action => "place"} }
    route.conditional_block.should be_an_instance_of(Proc)
    route.compile.should match(/block_result/m)
  end
end

describe Merb::Router::Behavior, "class methods" do
  before(:all) do
    @b = Merb::Router::Behavior
  end
  
  it "should count opening parentheses" do
    @b.count_parens_up_to(" ( )", 1).should == 1
    @b.count_parens_up_to(" ( )", 50).should == 1
    @b.count_parens_up_to(" (() )", 1).should == 1
    @b.count_parens_up_to(" (() )", 2).should == 2
    # TODO: skip escaped open parens
  end
  
  it "should concatenate strings without endcaps" do
    @b.concat_without_endcaps(nil, nil).should be_nil
    @b.concat_without_endcaps(nil, "^test").should == "^test"
    @b.concat_without_endcaps("my$", nil).should == "my$"
    @b.concat_without_endcaps("my", "test").should == "mytest"
    @b.concat_without_endcaps("my$", "test").should == "mytest"
    @b.concat_without_endcaps("my^", "test").should == "my^test"
    @b.concat_without_endcaps("my$", "^test").should == "mytest"
    @b.concat_without_endcaps("^my$", "^test$").should == "^mytest$"
  end
  
  it "should compile arrays with strings and symbols into code" do
    @b.array_to_code([:var, "this string"]).should == "var + \"this string\""
    @b.array_to_code(["one string"]).should == "\"one string\""
    @b.array_to_code(["string", :var, :var2, "other"]).should == "\"string\" + var + var2 + \"other\""
  end
end

describe "Merb::Route", "rendered as a string" do
  before(:all) do
    Merb::Router.prepare do |r|
      r.default_routes
    end
    @routes = Merb::Router.routes
  end
  
  it "should show the default route" do
    @routes.last.to_s.should == "/:controller(/:action(/:id)?)?(\\.:format)?"
  end
end

describe Merb::Router, "with resources using namespace 'admin'" do
  before(:each) do
    Merb::Router.prepare do |r|
      #Declare one in the nested style
      r.match(:host => /^.*$/).to(:namespace => 'admin') do |admin|
        admin.resources :oranges
      end
      #Declare one in the non-nested style
      r.resources :ape, :namespace => 'admin'
      #Declare resources without a namespace to make sure it's not overridden
      r.resources :oranges
      r.resource :ape
    end
  end
  
  it "should generate admin_oranges path" do
    Merb::Router.generate(:admin_oranges).should == '/oranges'
  end

  it "should generate admin_orange path" do
    Merb::Router.generate(:admin_orange, {:id => 1}).should == '/oranges/1'
    b = Blogposts.new
    Merb::Router.generate(:admin_orange, b).should == '/oranges/42'
    Merb::Router.generate(:admin_orange, :id => b).should == '/oranges/42'
  end
  
  it "should generate new_admin_orange path" do
    Merb::Router.generate(:new_admin_orange).should == '/oranges/new'
  end
  
  it "should generate edit_admin_orange path" do
    Merb::Router.generate(:edit_admin_orange, {:id => 1}).should == '/oranges/1/edit'
  end  
  
  it "should generate admin_ape path" do
    Merb::Router.generate(:admin_ape).should == '/ape'
  end

  it "should generate new_admin_ape path" do
    Merb::Router.generate(:new_admin_ape).should == '/ape/new'
  end
  
  it "should generate edit_admin_ape path" do
    Merb::Router.generate(:edit_admin_ape).should == '/ape/edit'
  end  

end