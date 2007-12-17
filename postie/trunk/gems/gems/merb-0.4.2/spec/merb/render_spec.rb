require 'stringio'
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/controllers/render_spec_controllers'

describe "rendering engines except XMLBuilder", :shared => true do
  it "should render a template" do
    c = new_controller
    content = c.render :template => "#{@engine}", :layout => :none
    content.clean.should == "Hello!"
  end

  it "should render a partial" do
    c = new_controller
    content = c.partial "partials/#{@engine}"
    content.clean.should == "No Locals!"
  end

  it "should render a partial with locals" do
    c = new_controller
    content = c.partial "partials/#{@engine}", :yo => "Locals!"
    content.clean.should == "Locals!"
  end

  it "should render a partial with nil locals" do
    c = new_controller
    content = c.partial "partials/#{@engine}", :yo => nil
    content.clean.should == "No Locals!"
  end

  it "should render a partial using the :partial method" do
    c = new_controller
    content = c.partial("partials/#{@engine}")
    content.clean.should == "No Locals!"
  end

  it "should render a partial using the :partial method with locals" do
    c = new_controller
    content = c.partial("partials/#{@engine}", :yo => "Locals!")
    content.clean.should == "Locals!"
  end

  it "should render a partial iterating over a collection" do
    c = new_controller
    content = c.partial("partials/#{@engine}_collection",
      :with => (1..10).to_a)
    content.clean.should == (1..10).to_a.join("\n")
  end

  it "should render a partial with an object" do
    c = new_controller
    content = c.partial("partials/#{@engine}_collection", :with => 1)
    content.clean.should == '1'
  end

  it "should allow you to overwrite the local var using :as when rendering a collection" do
    c = new_controller
    content = c.partial("partials/#{@engine}_collection_with_locals", :with => (1..10).to_a, :as => :number)
    content.clean.should == (1..10).to_a.join("\n")
  end

  it "should allow you to overwrite the local var using :as when render an object" do
    c = new_controller
    content = c.partial("partials/#{@engine}_collection_with_locals", :with => 1, :as => :number)
    content.clean.should == '1'
  end

  it "should render a partial iterating over a collection with extra locals" do
    c = new_controller
    content = c.partial("partials/#{@engine}_collection_with_locals", :with => (1..10).to_a, :number => 'Locals!')
    content.clean.should == (1..10).to_a.map { |i| "Locals!" }.join("\n")
  end

  it "should render a partial using the .format.engine convention" do
    c = new_controller
    content = c.partial "partials/#{@engine}_new"
    content.clean.should == "No Locals!"
  end
  
  it "should render a template without a layout" do
    c = new_controller
    content = c.render_no_layout(:template => "#{@engine}")
    content.clean.should == "Hello!"
  end

  it "should raise an exception without a template" do
    c = new_controller(nil, Examples)
    lambda {
      c.render_no_layout(:template => nil)
    }.should raise_error(Merb::ControllerExceptions::TemplateNotFound)
  end

  it "should find a snake case partial" do
    c = new_controller(nil, Examples)
    content = c.partial("#{@engine}")
    content.clean.should == "Hello!"
  end

  it "should implement a _buffer method" do
    c = new_controller
    content = c.render :template => "template_views/interface__buffer_#{@engine}", :layout => :none
    content.should match( /respond_to\?\(\s*\:_buffer\s*\)\s+\=\s+TRUE/ )
    content.should match( /Text for the view buffer/ )
  end
      
  it "should implement a concat( text, binding ) method" do
    c = new_controller
    content = c.render :template => "template_views/interface_concat_#{@engine}", :layout => :none
    content.should match( /Concat Text/ )
  end

  it "should bind the concat to a block" do
    c = new_controller
    content = c.render :template => "template_views/interface_concat_#{@engine}", :layout => :none
    content.should match( /Start Tester Block\s*In Tester Block\s*Finish Tester Block/m)
  end

  it "should bind the concat to independent render buffers" do
    c = new_controller
    content = c.render :template => "template_views/interface_concat_#{@engine}", :layout => :none
    content.should match( /Start Tester Block\s*In Tester Block\s*Finish Tester Block/m)
    content = c.render :template => "template_views/interface_concat_#{@engine}", :layout => :none
    content.should match( /Start Tester Block\s*In Tester Block\s*Finish Tester Block/m)
  end
  
  it "should implement a capture( &block ) method" do
    c = new_controller
    content = c.render :template => "template_views/interface_capture_#{@engine}", :layout => :none
    content.should match( /Capture Text Without Args/m)
  end
  
  it "should render #{@engine} partial using .format.engine convention#{" (caching on)" if defined?(cache) && cache}" do
    c = new_controller
    content = c.partial "partials/#{@engine}_new"
    content.clean.should == "No Locals!"
  end

  # # These cannot be implemented at this stage with Markaby without instance_exec which will
  # # not be available until Ruby 1.9
  # it "should implement capture and yield arguments to the block for #{@engine}" do
  #   c = new_controller
  #   content = c.render :template => "template_views/interface_capture_#{@engine}", :layout => :none
  #   content.should match( /capture text from yielded object/im)
  # end
  #
  # # This cannot be specced until Ruby 1.9 is available due to instance_exec
  # # unless markaby can be made to accept arguments for this method.
  # it "should capture content in a block for #{@engine}" do
  #   c = new_controller
  #   content = c.render :template => "template_views/interface_capture_#{@engine}", :layout => :none
  #   content.should match( /BEFORE\s*capture text from yielded object\s*AFTER/im)
  # end
end

[true, false].each do |cache|
  Merb::Server.config[:cache_templates] = cache

  describe "Merb rendering in general#{" (caching enabled)" if cache}" do
    it "should render inline with Erubis" do
      c = new_controller
      content = c.render :inline => "<%= 'Inline' %>", :layout => :none
      content.clean.should == "Inline"
    end

    it "should render an XML string" do
      c = new_controller(nil, Examples)
      content = c.render :xml => "<hello>world</hello>"
      content.clean.should == "<hello>world</hello>"
      c.headers["Content-Type"].should == "application/xml"
      c.headers["Encoding"].should == "UTF-8"
    end

    it "should render a javascript string" do
      c = new_controller(nil, Examples)
      content = c.render(:js => "alert('Hello, world!');")
      content.clean.should == %{alert('Hello, world!');}
    end

    it "should raise an TemplateNotFound error if a template is called that does not exist" do
      c = new_controller(nil, Examples)
      lambda do
        c.render(:template => "does_not_exist", :format => :html)
      end.should raise_error(Merb::ControllerExceptions::TemplateNotFound)      
    end
    
    it "should render a template from a directory with a . in it's path" do
      c = new_controller(nil, Examples)
      lambda do
        c.render(:template => "test.dir/the_template", :format => :html)
      end.should_not raise_error(Merb::ControllerExceptions::TemplateNotFound)
    end
    
  end

  describe "Merb rendering with the Erubis engine#{" (caching enabled)" if cache}" do
    before(:all) { @engine = "erubis" }
    it_should_behave_like "rendering engines except XMLBuilder"

    it "should render a nested controller's views" do
      c = new_controller(nil, Nested::Example)
      content = c.render(:action => "test")
      content.clean.should == "Hello!"
    end

    it "should report the selected template in controller._template" do
      c = new_controller
      content = c.render(:template => "erubis")
      c.template.should == "erubis.html.erb"
    end

    it "should raise LayoutNotFound if the layout is missing" do
      c = new_controller
      lambda {
        c.render(:template => "erubis", :layout => "this_is_not_a_layout")
      }.should raise_error(Merb::ControllerExceptions::LayoutNotFound)
    end

    it "should render the index action using index.html.erb" do
      c = new_spec_controller
      c.dispatch(:index)
      c.template.should == "index.html.erb"
    end

    it "should render an erubis .html.erb template" do
      c = new_spec_controller(:format => 'html')
      c.dispatch(:erubis_templates)
      c.template.should == "erubis_templates.html.erb"
    end

    it "should render an .html.erb template in front of a erubis_templates.rhtml" do
      c = new_spec_controller(:format => 'html')
      c.dispatch(:erubis_templates)
      c.template.should == "erubis_templates.html.erb"
    end

    it "should render an erubis .js.erb template" do
      c = new_spec_controller(:format => 'js')
      c.dispatch(:erubis_templates)
      c.template.should == "erubis_templates.js.erb"
    end

    it "should render an erubis .xml.erb template" do
      c = new_spec_controller(:format => 'xml')
      c.dispatch(:erubis_templates)
      c.template.should == "erubis_templates.xml.erb"
    end
    
    it "should render js in nested partials when the format is javascript" do
      c = new_spec_controller
      c.dispatch(:render_nested_js)      
      c.body.should match(/nested_js_partial/m)
    end
    
    it "should render xml in nested partials when the format is xml" do
      c = new_spec_controller
      c.dispatch(:render_nested_xml)      
      c.body.should match(/nested_xml_partial/m)
    end
    
    it "should render multiple partials with locals" do
      c = new_spec_controller(:controller => "ExtensionTemplateController")
      c.dispatch(:render_multiple_partials)
      (1..10).each do |i|
        c.body.should match(/#{i}/)
      end    
    end

  end

  describe "Merb rendering with the Markaby engine#{" (caching enabled)" if cache}" do
    before(:all) { @engine = "markaby" }
    it_should_behave_like "rendering engines except XMLBuilder"

    it "should render markaby_index using markaby_index.html.mab" do
      c = new_spec_controller
      c.dispatch(:markaby_index)
      c.template.should == "markaby_index.html.mab"
    end

    it "should render a markaby .html.mab template" do
      c = new_spec_controller(:format => 'html')
      c.dispatch(:markaby_templates)
      c.template.should == "markaby_templates.html.mab"
    end

    it "should render a markaby .js.mab template" do
      c = new_spec_controller(:format => 'js')
      c.dispatch(:markaby_templates)
      c.template.should == "markaby_templates.js.mab"
    end

    it "should render a markaby .xml.mab template" do
      c = new_spec_controller(:format => 'xml')
      c.dispatch(:markaby_templates)
      c.template.should == "markaby_templates.xml.mab"
    end
  end

  # XMLBuilder and Haml templates aren't supported under JRuby yet
  unless RUBY_PLATFORM =~ /java/
    describe "Merb rendering with the Haml engine#{" (caching enabled)" if cache}" do
      before(:all) { @engine = "haml" }
      it_should_behave_like "rendering engines except XMLBuilder"

      it "should render haml_index using haml_index.html.haml" do
        c = new_spec_controller
        c.dispatch(:haml_index)
        c.template.should == "haml_index.html.haml"
      end

      it "should render an haml .html.haml template" do
        c = new_spec_controller(:format => 'html')
        c.dispatch(:haml_templates)
        c.template.should == "haml_templates.html.haml"
      end

      it "should render an haml .js.haml template" do
        c = new_spec_controller(:format => 'js')
        c.dispatch(:haml_templates)
        c.template.should == "haml_templates.js.haml"
      end

      it "should render an haml .xml.haml template" do
        c = new_spec_controller(:format => 'xml')
        c.dispatch(:haml_templates)
        c.template.should == "haml_templates.xml.haml"
      end

    end

    describe "Merb rendering with the XMLBuilder engine#{" (caching enabled)" if cache}" do
      before(:all) { @engine = "builder" }

      it "should render an XML template from a symbol" do
        c = new_controller(nil, Examples)
        content = c.render :xml => :hello
        content.clean.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hello>world</hello>"
        c.headers["Content-Type"].should == "application/xml"
      end

      it "should render an XML template from an action" do
        c = new_controller(nil, Examples)
        content = c.render :xml => true, :action => "hello"
        content.clean.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hello>world</hello>"
        c.headers["Content-Type"].should == "application/xml"
      end

    end
  end

end

describe "Merb rendering with an object calls to_json or to_xml on the object" do
  it "render @foo should call @foo.to_json when json is requested" do
      c = new_spec_controller(:format => 'json', :controller => 'RenderObjectController')
      c.dispatch(:render_object)
      c.body.should == "{'foo':'bar'}"
  end
  
  it "render @foo should call @foo.to_xml when json is requested" do
      c = new_spec_controller(:format => 'xml', :controller => 'RenderObjectController')
      c.dispatch(:render_object)
      c.body.should == "<foo>bar</foo>" 
  end
  
  it "should render the template for the action when called with an object and the template exists" do
    c = new_spec_controller(:format => :html, :controller => 'RenderObjectController')
    c.dispatch(:render_object_with_template)
    c.body.should match(/object with template html format/)
  end
  
  it "should render the template for the action when called with an object and the template exists" do
    c = new_spec_controller(:format => :xml, :controller => 'RenderObjectController')
    c.dispatch(:render_object_with_template)
    c.body.should match(/object with template xml format/)
  end
  
  it "should render the template for the action when called with an object and the template exists" do
    c = new_spec_controller(:format => :js, :controller => 'RenderObjectController')
    c.dispatch(:render_object_with_template)
    c.body.should match(/object with template js format/)
  end
  
end

describe "Merb rendering with an object calls to_json or to_xml on the object (using specified arguments)" do
  
  it "render @foo should call @foo.to_json when json is requested (using default options)" do
    c = new_spec_controller(:format => 'json', :controller => 'RenderObjectWithArgumentsController')
    c.provided_format_arguments_for(:json).should == ["foo", "bar"]
    c.dispatch(:render_standard)
    c.body.should == "['foo','bar']"
  end
  
  it "render @foo should call @foo.to_json when json is requested (using action options)" do
    c = new_spec_controller(:format => 'json', :controller => 'RenderObjectWithArgumentsController')
    c.dispatch(:render_specific)
    c.body.should == "['foo','bar','baz']"
  end
  
  it "render @foo should call @foo.to_xml when xml is requested (using default options)" do
    c = new_spec_controller(:format => 'xml', :controller => 'RenderObjectWithArgumentsController')
    c.provided_format_arguments_for(:xml).should == [{:foo=>"bar"}]
    c.dispatch(:render_standard)
    c.body.should == "<foo>bar</foo>"
  end
  
  it "render @foo should call @foo.to_xml when xml is requested (using action options)" do
    c = new_spec_controller(:format => 'xml', :controller => 'RenderObjectWithArgumentsController')
    c.dispatch(:render_specific)
    c.body.should == "<biz>baz</biz><foo>bar</foo>"
  end
  
end

describe "Merb rendering with an object and using a block/lambda for provides" do
  
  it "render @foo should use the default block when xml is requested" do
    c = new_spec_controller(:format => 'xml', :controller => 'RenderObjectWithBlockController')
    c.provided_format_arguments_for(:xml).should be_kind_of(Proc)
    c.dispatch(:render_standard)
    c.body.should == "<foo>RenderObjectWithBlockController</foo>"
  end
  
  it "render @foo should use the default block when json is requested" do
    c = new_spec_controller(:format => 'json', :controller => 'RenderObjectWithBlockController')
    c.provided_format_arguments_for(:json).should be_kind_of(Proc)
    c.dispatch(:render_standard)
    c.body.should == "['foo']"
  end
  
  it "render @foo should use the specific proc when xml is requested" do
    c = new_spec_controller(:format => 'xml', :controller => 'RenderObjectWithBlockController')
    c.dispatch(:render_specific)
    c.body.should == "<foo>RENDEROBJECTWITHBLOCKCONTROLLER</foo>"
  end
  
  it "render @foo should use the specific proc when json is requested" do
    c = new_spec_controller(:format => 'json', :controller => 'RenderObjectWithBlockController')
    c.dispatch(:render_specific)
    c.body.should == "['RenderObjectWithBlockController','foo','bar','baz']"
  end
  
end

def new_spec_controller(options={})
  params = {:controller => 'ExtensionTemplateController'}
  params.update(:format => options.delete(:format)) if options[:format]
  params.update(:controller => options[:controller]) if options[:controller]
  @request = Merb::Test::FakeRequest.new(options)
  @request.params.merge!(params)
  Object.const_get(params[:controller].to_sym).build(@request, @request.body)
end
