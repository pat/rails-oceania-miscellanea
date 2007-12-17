require File.dirname(__FILE__) + '/../spec_helper'
Merb::Template::Erubis # Need to initialise the Erubis template

class Main < Merb::Controller
  
  def index
    part TodoPart => :list
  end
  
  def index2
    part TodoPart => :one
  end
  
  def index3
    part(TodoPart => :one) + part(TodoPart => :list)
  end
  
  def index4
    provides [:xml, :js]
    part(TodoPart => :formatted_output)
  end
  
end  


class TodoPart < Merb::PartController
  self._template_root = File.expand_path(File.join(File.dirname(__FILE__), '..', "fixtures/parts/views"))
  
  before :load_todos
  
  def list
    render
  end
  
  def one
    render :layout => :none, :action => :list
  end
  
  def load_todos
    @todos = ["Do this", "Do that", 'Do the other thing']
  end
  
  def formatted_output
    render
  end

end

describe "A Merb PartController" do
  
  before(:each) do
    Merb::Router.prepare do |r|
      r.default_routes
    end
  end  
  
  it "should render a part template with no layout" do
    controller,action = request(:get, '/main/index2')
    controller.body.should ==
      "TODOPART\nDo this|Do that|Do the other thing\nTODOPART"
  end
  
  it "should render a part template with it's own layout" do
    controller,_ = request(:get, '/main/index')
    controller.body.should ==
      "TODOLAYOUT\nTODOPART\nDo this|Do that|Do the other thing\nTODOPART\nTODOLAYOUT"
  end 
  
  it "should render multiple parts if more then one part is passed in" do
    controller,_ = request(:get, '/main/index3')
    controller.body.should ==
      "TODOPART\nDo this|Do that|Do the other thing\nTODOPART" +
      "TODOLAYOUT\nTODOPART\nDo this|Do that|Do the other thing\nTODOPART\nTODOLAYOUT"
  end 
  
  it "should render the html format by default to the controller that set it" do
    controller,_ = request(:get, '/main/index4')
    controller.body.should match(/part_html_format/m)
    
  end
  
  it "should render the xml format according to the controller" do
    controller,_ = request(:get, '/main/index4.xml')
    controller.body.should match(/part_xml_format/m)
  end

  it "should render the xml format according to the controller" do
    controller,_ = request(:get, '/main/index4.js')
    controller.body.should match(/part_js_format/m)
  end
  
end  

describe "A Merb Part Controller with urls" do
  
  it_should_behave_like "class with general url generation"
  it_should_behave_like "non routeable controller with url mixin"
  
  def new_url_controller(route, params = {:action => 'show', :controller => 'Test'})
    request = OpenStruct.new
    request.route = route
    request.params = params
    response = OpenStruct.new
    response.read = ""
    
    @controller = Merb::Controller.build(request, response)
    TodoPart.new(@controller)
  end
  
  it "should use the web_controllers type if no controller is specified" do
    c = new_url_controller(@default_route, :controller => "my_controller")
    the_url = c.url(:action => "bar")
    the_url.should == "/my_controller/bar"
  end
  
  it "should raise an error if the web_controller's params[:controller] is not set" do
    c = new_url_controller(@default_route, {})
    lambda do
      the_url = c.url(:action => "bar")
      the_url.should == "/my_controller/bar"
    end.should raise_error
  end
  
end