require 'merb/test/fake_request'
require 'merb/test/hpricot'
include HpricotTestHelper

module Merb
  module Test
    module Helper
      # Create a FakeRequest suitable for passing to Controller.build
      def fake_request(path="/",method='GET')
        method = method.to_s.upcase
        Merb::Test::FakeRequest.with(path, :request_method => method)
      end

      # Turn a named route into a string with the path
      # This is the same method as is found in the controller
      def url(name, *args)
        Merb::Router.generate(name, *args)
      end


      # For integration/functional testing


      def request(verb, path)
        response = StringIO.new
        @request = Merb::Test::FakeRequest.with(path, :request_method => (verb.to_s.upcase rescue 'GET'))
  
        yield @request if block_given?
  
        @controller, @action = Merb::Dispatcher.handle @request, response
      end

      def get(path)
        request("GET",path)
      end
      
      def controller
        @controller
      end
      
      [:body, :status, :params, :cookies, :headers,
        :session, :response, :route].each do |method|
        define_method method do
          controller ? controller.send(method) : nil
        end
      end
      
      # Checks that a route is made to the correct controller etc
      # 
      # === Example
      # with_route("/pages/1", "PUT") do |params|
      #   params[:controller].should == "pages"
      #   params[:action].should == "update"
      #   params[:id].should == "1"
      # end
      def with_route(the_path, _method = "GET")
        result = Merb::Router.match(fake_request(the_path, _method), {})
        yield result[1] if block_given?
        result
      end 

      def fixtures(*files)
        files.each do |name|
          klass = Kernel::const_get(Inflector.classify(Inflector.singularize(name)))
          entries = YAML::load_file(File.dirname(__FILE__) + "/fixtures/#{name}.yaml")
          entries.each do |name, entry|
            klass::create(entry)
          end
        end
      end


      # Dispatches an action to a controller.  Defaults to index.  
      # The opts hash, if provided will act as the params hash in the controller
      # and the params method in the controller is infact the provided opts hash
      # This controller is based on a fake_request and does not go through the router
      # 
      # === Simple Example
      #  {{{
      #    controller, result = dispatch_to(Pages, :show, :id => 1, :title => "blah")
      #  }}}
      #
      # === Complex Example
      # By providing a block to the dispatch_to method, the controller may be stubbed or mocked prior to the 
      # actual dispatch action being called.
      #   {{{
      #     controller, result = dispatch_to(Pages, :show, :id => 1) do |controller|
      #       controller.stub!(:render).and_return("rendered response")
      #     end
      #   }}}
      def dispatch_to(controller, action = :index, opts = {})
        klass = controller.class == Class ? controller : controller.class
        klass.stub!(:find_by_title).and_return(@page)
        the_controller = klass.build(fake_request)
        the_controller.stub!(:params).and_return(opts.merge!(:controller => "#{klass.name.downcase}", :action => action.to_s))

        yield the_controller if block_given?
        @controller = the_controller
        [the_controller, the_controller.dispatch(action.to_sym)]
      end
    end
  end
end
