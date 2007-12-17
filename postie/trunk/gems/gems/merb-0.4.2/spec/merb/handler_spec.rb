require File.dirname(__FILE__) + '/../spec_helper'

describe MerbHandler, "process" do
  
  def do_process
    @handler.process( @request, @response )
  end
  
  def log_info_with( with_param )
    MERB_LOGGER.should_receive(:info).with( with_param )
  end
  
  before(:each) do
    @params = { Mongrel::Const::REQUEST_METHOD  => "GET",
                Mongrel::Const::PATH_INFO       => "PUBLIC",
                Mongrel::Const::REQUEST_URI     => "www.example.com/file" }
                
    
    @static_file_handler = mock( "mongrel_dir_handler", :null_object => true )
    @static_file_handler.stub!( :can_serve ).and_return( false )
    Mongrel::DirHandler.stub!(:new).and_return( @static_file_handler ) # Need to get a handle on the dir handler in initialize
    
    @handler = MerbHandler.new( "public" )
    
    @response = mock( "response",  :null_object => true )
    @response.stub!( :socket ).and_return( mock( "socket" ) )
    @response.socket.stub!( :closed? ).and_return( false )
    
    @request = mock( "request",    :null_object => true )
    @request.stub!( :params ).and_return( @params )

    @benchmarks = { :setup_time => 1 }
    @controller = mock( "controller", :null_object => true )
    @controller.stub!(:class).and_return( "CONTROLLER_CLASS" )
    @controller.stub!(:_benchmarks).and_return( @benchmarks )
    @action = "ACTION"
    Merb::Dispatcher.stub!( :handle ).and_return( [@controller, @action] )

    MERB_LOGGER.stub!(:info)
  end

  it "should return nil if the socket is closed" do
    @response.socket.stub!( :closed? ).and_return( true )
    do_process.should be_nil
  end
  
  it "should log the request URI to the MERB_LOGGER.info" do
    log_info_with( /REQUEST_URI/ )
    do_process
  end
  
  
  it "should serve static files" do
    @static_file_handler.stub!( :can_serve ).and_return( true )
    log_info_with( /static/i )
    @static_file_handler.should_receive( :process ).with( @request, @response )
    do_process
  end
  
  it "should fall back to .html and try and serve the file" do
    @static_file_handler.should_receive( :can_serve ).with( "PUBLIC.html" ).and_return( true )
    @static_file_handler.should_receive( :process ).with( @request, @response )
    log_info_with( /static/i )
    do_process
    @request.params[Mongrel::Const::PATH_INFO].should == "PUBLIC.html"
  end
  
  it "should ask the Dispatcher for the controller and action" do
    Merb::Dispatcher.should_receive( :handle ).with( @request, @response )
    do_process
  end
  
  it "should log any exceptions that reach the handler and return 500" do
    @out = ""
    @head = {}
    Merb::Dispatcher.should_receive( :handle ).and_raise( Exception )
    @response.should_receive( :send_status ).with( 500 )
    MERB_LOGGER.should_receive(:error)
    do_process
  end
  
  it "should set the response.status to the controller.status" do
    @controller.should_receive( :status ).and_return( "SPEC_STATUS" )
    @response.should_receive( :status= ).with( "SPEC_STATUS" )
    do_process
  end
  
  it "should handle the X-SENDFILE header" do
    @controller.should_receive( :headers ).and_return( { "X-SENDFILE" => __FILE__ } )
    log_info_with( /X-SENDFILE/im )
    @response.should_receive( :status= ).with( 200 )
    @response.header.should_receive( :[]= ).with( Mongrel::Const::LAST_MODIFIED, an_instance_of( String ) )
    @response.header.should_receive( :[]= ).with( Mongrel::Const::ETAG, anything() )
    @response.should_recieve( :send_status ).with( File.size( __FILE__ ) )
    @response.should_receive( :send_header )
    @response.should_receive( :send_file )
    
    do_process
  end
  
  it "should setup the headers" do
    @response_header = {}
    @controller.should_receive( :headers ).and_return( { "X-MY_HEADER" => "MY_HEADER_CONTENT" } )
    @response.should_receive( :header ).and_return( @response_header )
    @response_header.should_receive( :[]= ).with( "X-MY_HEADER", "MY_HEADER_CONTENT" )
    do_process
  end
  
  
  it "should handle a controller body that can be read" do
    # This is a bit dependent on implementation
    @controller.should_receive( :headers ).and_return( { "CONTENT-LENGTH" => 5 } )
    @body = Object.new
    @body.stub!( :close ).and_return( true )
    @body.stub!( :read ).and_return( false )
    @body.should_receive( :read ).and_return( true, true, false )
    @controller.stub!( :body ).and_return( @body )
    @response.should_receive( :send_status ).with( 5 )
    @response.should_receive( :send_header )
    @response.should_receive( :write ).at_least( :once )
    @body.should_receive( :close )
    
    do_process
  end
  
  it "should handle a controller body that is a proc" do
    @proc = Proc.new { "PROC_CONTENTS" }
    @controller.should_receive( :body ).at_least(:once).and_return( @proc )
    @proc.should_receive( :call )    
    do_process
  end
  
  it "should spit out a normal rendering of the controller" do
    @body = "CONTROLLER_BODY"
    @controller.stub!( :body ).and_return( @body )
    @controller.should_receieve( :body ).at_least( :once ).and_return( @body )
    
    @response.should_receive( :send_status ).with( @body.length )
    @response.should_receive( :send_header )
    @response.should_receive( :write ).with( @body )
    
    do_process
  end
  
  it "should log the controller and action called" do
    log_info_with( /Routing to.+CONTROLLER_CLASS.+ACTION/ )
    do_process
  end
  
  it "should render the request times" do
    log_info_with( /request times/i )
    do_process
  end
  
  it "should render the Response status" do
    log_info_with( /response status/i )
    do_process
  end
  
  it "should remove path_prefix from the request_uri and path_info environment variables" do
    MerbHandler.path_prefix = "/prefix"
    @request.params[Mongrel::Const::PATH_INFO] = "/prefix/PUBLIC"
    @request.params[Mongrel::Const::REQUEST_URI] = "/prefix/file"
    do_process
    @request.params[Mongrel::Const::PATH_INFO].should == "/PUBLIC"
    @request.params[Mongrel::Const::REQUEST_URI].should == "/file"
    MerbHandler.path_prefix = nil
  end
end
