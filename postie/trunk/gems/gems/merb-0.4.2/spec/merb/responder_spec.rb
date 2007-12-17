require File.dirname(__FILE__) + '/../spec_helper'

module ResponderSpecModule
  def new_mime(entry,index)
    Merb::ResponderMixin::Rest::AcceptType.new(entry,index)
  end
end

describe "The Merb Module" do
  
  after do
    Merb.reset_default_mime_types!
  end
  
  it "should respond to add_mime_type" do
    Merb.should respond_to(:add_mime_type)
  end
  it "should respond to remove_mime_type" do
    Merb.should respond_to(:remove_mime_type)
  end
  it "should respond to available_mime_types" do
    Merb.should respond_to(:available_mime_types)
  end
  it "should respond to outgoing_headers" do
    Merb.should respond_to(:response_headers)
  end
  it "should respond to add_outgoing_headers!" do
    Merb.should respond_to(:add_response_headers!)    
  end
  it "should respond to remove_outgoing_headers!" do
    Merb.should respond_to(:remove_response_headers!)    
  end
  
  it "should give access to the available_mime_types" do
    Merb.available_mime_types.should equal(Merb::ResponderMixin::Rest::TYPES)   
  end
  
  it "should add a mime type to the TYPES array" do
    Merb::ResponderMixin::Rest::TYPES.has_key?(:png).should be_false
    Merb.add_mime_type(:png, :to_png, %w[image/png])
    Merb::ResponderMixin::Rest::TYPES.has_key?(:png).should be_true
  end
  it "should only accept Symbols for add_mime_type's key argument" do
    lambda{
      Merb.add_mime_type('silly string', %w[string/silly])
    }.should raise_error(ArgumentError)
  end
  it "should only accept an Array for add_mime_type's values argument" do
    lambda{Merb.add_mime_type(:key, :to_key, 'Congos')}.should raise_error(ArgumentError)
  end
  it "should remove a mime type from the TYPES array" do
    Merb.add_mime_type(:png, :to_png, %w[image/png])
    Merb::ResponderMixin::Rest::TYPES.has_key?(:png).should be_true
    Merb.remove_mime_type(:png)
    Merb::ResponderMixin::Rest::TYPES.has_key?(:png).should be_false
  end
  it "should not allow removal of the special :all mime-type" do
    Merb.remove_mime_type(:all).should be_false
    Merb::ResponderMixin::Rest::TYPES.has_key?(:all).should be_true
  end
    
  it "should add a mime type with outgoing headers defined" do
    Merb.available_mime_types.should_not have_key(:pdf)
    Merb.response_headers.should_not have_key?(:pdf)
    Merb.mime_transform_method(:pdf).should be_nil
    Merb.add_mime_type(:pdf, :to_pdf, %w[application/pdf],{"Content-Encoding" => "gzip"})
    Merb.available_mime_types.should have_key(:pdf)
    Merb.available_mime_types[:pdf].should == %w[application/pdf]
    Merb.response_headers.should  have_key(:pdf)
    Merb.response_headers[:pdf].should == { "Content-Encoding" => "gzip" }
    Merb.mime_transform_method(:pdf).should == :to_pdf
  end
  
  it "should add an outgoing header for an existing mime type" do
    Merb.response_headers[:html].should be_empty
    Merb.add_response_headers!(:html,{:header => "content"}) 
    Merb.response_headers[:html].should == {:header => "content"}  
  end
  
  it "should set the transform for the default html to nil" do
    Merb.available_mime_types.should have_key(:html)
    Merb.mime_transform_method(:html).should be_nil
    
  end
  
  it "should set xml to default to :Encoding => 'UTF-8'" do
    Merb.response_headers[:xml].should == {:Encoding => "UTF-8"}    
  end
  
  it "should set the xml transform method to :to_xml" do
    Merb.mime_transform_method(:xml).should == :to_xml
  end
  
  it "should set the :js transform method to :to_json" do
    Merb.mime_transform_method(:js).should == :to_json
  end
  
  it "should replace any and all existing headers on an existing mime type" do
    header = {:header => "content"}
    Merb.response_headers[:xml].should_not be_empty
    Merb.response_headers[:xml].should_not == header
    Merb.add_response_headers!(:xml, header)
    Merb.response_headers[:xml].should == header
  end
  
  it "the specs should not alter the outgoing headers between specs" do
    Merb.response_headers[:xml].should == {:Encoding => "UTF-8"}
  end
  
  it "should remove all existing headers for a given mime type" do
    Merb.response_headers[:xml].should_not be_empty
    Merb.remove_response_headers!(:xml)
    Merb.response_headers[:xml].should be_empty
  end  
end

describe "A Merb Responder's AcceptType" do
  include ResponderSpecModule
  
  before :each do
    @app_xhtml = new_mime('application/xhtml+xml',1)
    @text_html = new_mime('text/html',5)
    @app_html  = new_mime('application/html;q=0.9',9)
  end
  
  it "should initialize properly from mime description and index" do
    acc_entry = new_mime('  application/html  ;   q=0.9  ',1)
    acc_entry.media_range.should == 'application/html'
    acc_entry.quality.should == 90
    acc_entry.index.should == 1
    acc_entry.synonyms.should == 
      %w[text/html application/xhtml+xml application/html]
    acc_entry.super_range.should == 'text/html'
    acc_entry.to_s.should == acc_entry.media_range
  end
  
  it "should assign lowest quality to */* unless otherwise specified" do
    new_mime('*/*',1).quality.should == 0
    new_mime('*/*;q=1.0',1).quality.should == 100
    new_mime('*/*;q=0.2',1).quality.should == 20
  end
  
  it "should be equal to another AcceptType in the same synonym group" do
    @text_html.should == @app_html
    @text_html.should eql(@app_html)
    @text_html.hash.should == @app_html.hash
  end
  
  it "should share a super range with an AcceptType in the same synonym group" do
    @text_html.synonyms.should == @app_html.synonyms
    @text_html.super_range.should == @app_html.super_range
  end
  
  it "should parse type and subtype" do
    @app_xhtml.type.should == 'application'
    @app_xhtml.sub_type.should == 'xhtml+xml'
    @text_html.type.should == 'text'
    @text_html.sub_type.should == 'html'
    @app_html.type.should == 'application'
    @app_html.sub_type.should == 'html'
  end

end

describe "A Merb Responder's parsing of an Accept header" do
  
  setup do
    @acc_hdr = "text/xml,application/xml,application/xhtml+xml," \
            "text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
  end
  
  it "should parse accept header string to Array of AcceptType instances" do
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(@acc_hdr)
    acc_hdr.should be_kind_of(Array)
    acc_hdr.all?{|e| e.kind_of?(Merb::ResponderMixin::Rest::AcceptType) }.should be_true
  end
  
  it "should parse single entry accept headers" do
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse('application/xml')
    acc_hdr.should be_kind_of(Array)
    acc_hdr.all?{|e| e.kind_of?(Merb::ResponderMixin::Rest::AcceptType) }.should be_true
  end
  
  it "should parse accept header into proper number of AcceptType instances" do
    acc_hdr = 'foo/bar,baz/quuz,chimi/changa,cobra/khai'
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(acc_hdr)
    acc_hdr.size.should == 4
  end
  
  it "should only return unique AcceptType instances" do
    acc_hdr = 'text/html,application/xhtml+xml,application/html,text/xml,' \
              'application/xml,application/x-xml'
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(acc_hdr)
    acc_hdr.size.should == 2
  end
  
  it "should sort AcceptType instances by quality" do
    acc_hdr = 'foo/bar;q=0.1,donny/darko;q=0.9,tango/cash,water/melon;q=0.5'
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(acc_hdr)
    acc_hdr.map!{|hdr| hdr.super_range }.should == 
      %w[tango/cash donny/darko water/melon foo/bar]
  end
  
  it "should sort AcceptType instances by order" do
    acc_hdr = 'foo/bar,baz/quuz,chimi/changa,cobra/khai'
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(acc_hdr)
    acc_hdr.map!{|hdr| hdr.super_range }.should == 
      %w[foo/bar baz/quuz chimi/changa cobra/khai]
  end
  
  it "should prefer alternate xml forms (foo+xml) over application/xml" do
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(@acc_hdr)
    acc_hdr.first.super_range.should == 'text/html'
  end
  
  it "should sort AcceptType instances by quality and order" do
    acc_hdr = Merb::ResponderMixin::Rest::Responder.parse(@acc_hdr)
    acc_hdr.map!{|hdr| hdr.super_range }.should == 
      %w[text/html application/xml image/png text/plain */*]
  end
  
end


class ResponderSpecController < Merb::Controller
  def index
    only_provides :html, :xml, :yaml
    content_type.to_s
  end
  
  def create
    only_provides :xml
    render :nothing => 201
  end
end

class CrazyResponderSpecController < Merb::Controller
  def index
    only_provides :donkey
    content_type
    "donkey"
  end  
end

Merb::Server.load_action_arguments
Merb::Server.load_controller_template_path_cache
Merb::Server.load_erubis_inline_helpers

describe "A Merb Responder's Content Negotiation" do

  it "should set Content-Type by :format for supported type: xml" do
    c = new_responder_spec_controller(:format => 'xml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/xml'
  end
  
  it "should set Content-Type by :format for supported type: yaml" do
    c = new_responder_spec_controller(:format => 'yaml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/x-yaml'
  end
  
  it "should set Content-Type by :format for supported type: html" do
    c = new_responder_spec_controller(:format => 'html')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'text/html'
  end
  
  it "should set Content-Type by accept header for supported type: xml" do
    c = new_responder_spec_controller(:http_accept => 'text/xml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/xml'
  end
  
  it "should set Content-Type by accept header for supported type: yaml" do
    c = new_responder_spec_controller(:http_accept => 'text/yaml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/x-yaml'
  end
  
  it "should set Content-Type by accept header for supported type: html" do
    c = new_responder_spec_controller(:http_accept => 'text/html')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'text/html'
  end
  
  it "should set Content-Type by :format in preference to accept headers when both are of a supported response type" do
    c = new_responder_spec_controller(:http_accept => 'text/plain', :format => 'yaml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/x-yaml'
  end
  
  it "should set status 406 when format is of an unsupported response type" do
    c = new_responder_spec_controller(:format => 'fromage')
    lambda{c.dispatch(:index)}.should raise_error(Merb::ControllerExceptions::NotAcceptable)    
  end
  
  it "should set status 406 when no accept header is of a unsupported response type" do
    c = new_responder_spec_controller(:http_accept => 'stale/crackers;q=0.7,camel/milk;q=1.0')
    lambda{c.dispatch(:index)}.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
  
  it "should raise 406 when negotiated type is not in TYPES" do
    r = Merb::Test::FakeRequest.new
    c = CrazyResponderSpecController.build(r, r.body)
    lambda{c.dispatch(:index)}.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
    
  it "should call the block for the supported response type yaml" do
    c = new_responder_spec_controller(:http_accept => 'text/yaml')
    c.dispatch(:index)
    c.body.should == "yaml"
  end
  
  it "should call the block for the supported response type xml" do
    c = new_responder_spec_controller(:http_accept => 'text/xml')
    c.dispatch(:index)
    c.body.should == "xml"
  end
  
  it "should call the block for the supported response type html" do
    c = new_responder_spec_controller(:http_accept => 'text/html')
    c.dispatch(:index)
    c.body.should == "html"
  end
  
  it "should utilise format in preference to accept header" do
    c = new_responder_spec_controller(:http_accept => 'text/html', :format => 'xml')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'application/xml'
  end
  
  it "should respond to the */* catchall accept header" do
    c = new_responder_spec_controller(:http_accept => '*/*')
    c.dispatch(:index)
    c.status.should == 200
    c.headers['Content-Type'].should == 'text/html'
  end
  
  it "should honor a return :nothing => status specified in the respond_to block" do
    c = new_responder_spec_controller(:http_accept => 'application/xml')
    c.dispatch(:create)
    c.status.should == 201
  end
  
  def new_responder_spec_controller(options={})
    params = {:controller => 'ResponderSpecController', :action => 'index'}
    params.update(:format => options.delete(:format)) if options[:format]

    @request = Merb::Test::FakeRequest.new(options)
    @request.params.merge!(params)
    ResponderSpecController.build(@request, @request.body)
  end
end

class SimpleResponder
  include Merb::ResponderMixin
end

describe "Merb::ResponderMixin", "negotiating content_type" do
  before(:each) do
    @responder = SimpleResponder.new
    @responder.stub!(:provided_formats).and_return([:html, :xml])
    @responder.stub!(:params).and_return({:format => "html"})
    @request = mock("request")
    @request.stub!(:accept).and_return("text/html")
    @responder.stub!(:request).and_return(@request)
  end

  it "should have a perform_content_negotiation" do
    @responder.should respond_to(:perform_content_negotiation)
  end
  
  it "should use provided_formats when params[:format] is nil" do
    @responder.stub!(:params).and_return({})
    @responder.should_receive(:provided_formats).
      at_least(:once).and_return([:html])
    @responder.perform_content_negotiation
  end
  
  it "should use provided_formats when params[:format] is not nil" do
    @responder.should_receive(:provided_formats).
      at_least(:once).and_return([:html])
    @responder.perform_content_negotiation
  end
  
  it "should use params[:format] when determining content_type" do
    @responder.should_receive(:params).at_least(:once).
      and_return({:format => "html"})
    @responder.perform_content_negotiation
  end

  it "should use request.accept when params[:format] is nil" do
    @responder.stub!(:params).and_return({})
    @responder.should_receive(:request).once.and_return(@request)
    @request.should_receive(:accept).once.and_return("text/html")
    @responder.perform_content_negotiation
  end

  it "should not use request.accept when params[:format] is not nil" do
    @responder.should_receive(:request).exactly(0).times
    @responder.perform_content_negotiation
  end
  
  it "should return :html when params[:format] = :html" do
    @responder.perform_content_negotiation.should == :html    
  end
  
  it "should raise NotAcceptable when params[:format] = :html but :html is not provided" do
    @responder.should_receive(:provided_formats).at_least(:once).
      and_return([:xml])
    lambda {@responder.perform_content_negotiation}.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
  
  it "should return :xml when it is the first provided and accepts is */*" do
    @responder.stub!(:provided_formats).and_return([:xml, :html])
    @responder.stub!(:params).and_return({})
    @request.should_receive(:accept).once.and_return("*/*")
    @responder.perform_content_negotiation.should == :xml
  end

  it "should return :xml when it is the first requested" do
    @responder.stub!(:provided_formats).and_return([:html, :xml, :text])
    @responder.stub!(:params).and_return({})
    @request.should_receive(:accept).once.and_return("text/xml, text/html")
    @responder.perform_content_negotiation.should == :xml
  end
  
  it "should raise NotAcceptable when accepts and provides do not intersect" do
    @responder.stub!(:provided_formats).and_return([:html, :text])
    @responder.stub!(:params).and_return({})
    @request.should_receive(:accept).once.and_return("text/xml, text/json")
    lambda {@responder.perform_content_negotiation}.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
  
  it "should short circuit and raise NotAcceptable when provided_formats is empty" do
    @responder.stub!(:provided_formats).and_return([])
    @responder.should_receive(:params).exactly(0).times
    @responder.should_receive(:request).exactly(0).times
    lambda {@responder.perform_content_negotiation}.should raise_error(Merb::ControllerExceptions::NotAcceptable)
  end
end

class DoubleProvides < Merb::Controller
  def double_provides ; provides :xml; @_content_type = :html ; provides :txt ; end
end

describe "Merb::ResponderMixin", "dealing with content_type variable" do
  it "should raise an error if provides is called after content_type has been determined" do
    c = new_controller("double_provides",DoubleProvides)
    lambda { c.double_provides }.should raise_error
  end
  
  it "should return false for content_type_set? when @_content_type is nil" do
    c = new_controller("double_provides",DoubleProvides)
    c.should_not be_content_type_set
  end

  it "should return true for content_type_set? when @_content_type is not nil" do
    c = new_controller("double_provides",DoubleProvides)
    c.instance_variable_set("@_content_type",:html)
    c.should be_content_type_set
  end
  
  it "should return @_content_type when content_type is called" do
    c = new_controller("double_provides",DoubleProvides)
    c.instance_variable_set("@_content_type",:html)
    c.content_type.should == :html
  end
  
  it "should allow content_type to be set directly" do
    c = new_controller()
    c.content_type=:txt
    c.content_type.should == :txt
  end
end

class FormattedBasic < Merb::Controller ; end
class WithXml < Merb::Controller ; provides :xml ; end
class XmlOnly < Merb::Controller ; only_provides :xml ; end
class ProvidesNothing < Merb::Controller ; does_not_provide :html ; end
class HtmlAgain < Merb::Controller ; provides :html ; end

class ManyProvides < Merb::Controller
  provides :html, :xml, :txt
  def noextra ; end
  def extra ; provides :json, :yaml ; end
end

describe "Responder", "managing provided formats (class)" do
  it "should have the default class_provided_formats of [:html]" do
    c = new_controller("index",FormattedBasic)
    c.class_provided_formats.should == [:html]
  end
  
  it "should add :xml to class_provided_formats when called with provides :xml" do
    c = new_controller("index",WithXml)
    c.class_provided_formats.should == [:html, :xml]
  end

  it "should only have :xml in class_provided_formats when called with only_provides :xml" do
    c = new_controller("index",XmlOnly)
    c.class_provided_formats.should == [:xml]
  end
  
  it "should have an empty class_provided_formats when called with does_not_provide :html" do
    c = new_controller("index",ProvidesNothing)
    c.class_provided_formats.should == []
  end

  it "should only have :html in class_provided_formats when called with provides :html (after other controllers have set it)" do
    c = new_controller("index",HtmlAgain)
    c.class_provided_formats.should == [:html]
  end
    
  it "should handle multiple provides added via class method" do
    c = new_controller("noextra",ManyProvides)
    c.provided_formats.should == [:html, :xml, :txt]
  end
end

class ActionProvides < Merb::Controller
  def basic ; end
  def with_xml ; provides :xml ; end
  def xml_only ; only_provides :xml ; end
  def nothing ; does_not_provide :html ; end
end

describe "Responder", "managing provided formats (action)" do
  it "should have the default provided_formats" do
    c = new_controller("basic",ActionProvides)
    c.basic
    c.provided_formats.should == [:html]
  end
  
  it "should add :xml to provided_formats when called with provides :xml" do
    c = new_controller("with_xml",ActionProvides)
    c.with_xml
    c.provided_formats.should == [:html, :xml]
  end
  
  it "should only have :xml in provided_formats when called with only_provides :xml" do
    c = new_controller("xml_only",ActionProvides)
    c.xml_only
    c.provided_formats.should == [:xml]
  end

  it "should have an empty provided_formats when called with does_not_provide :html" do
    c = new_controller("nothing",ActionProvides)
    c.nothing
    c.provided_formats.should be_empty
  end
end

