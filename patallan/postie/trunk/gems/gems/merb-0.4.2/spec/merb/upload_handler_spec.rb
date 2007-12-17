require File.dirname(__FILE__) + '/../spec_helper'

describe MerbUploadHandler do
  before(:each) do
    @progress = mock(:upload_progress)
    @progress.stub!(:debug)
    @progress.stub!(:update_checked_time)
    @progress.stub!(:add)
    @progress.stub!(:mark)
    @progress.stub!(:finish)
    @progress.stub!(:last_checked).and_return Time.now - 10
    Merb::UploadProgress.stub!(:new).and_return(@progress)
    @handler   = MerbUploadHandler.new(:upload_frequency => 3, :upload_path_match => '^/files/\d+')
    @upload_id = '880b7835-8a67-400e-a8f1-dec18691d604'
    @params    = {
      'CONTENT_LENGTH' => "10",
      'PATH_INFO' => '/files/23',
      'REQUEST_METHOD' => 'POST',
      'QUERY_STRING' => "upload_id=#{@upload_id}"
    }
    @request  = mock(:request)
    @request.stub!(:params).and_return(@params)
    @response = mock(:response)
  end
  
  after(:each) do
    Mongrel.class_eval do
      remove_const :Uploads
    end
  end
  
  it "should consider requests as invalid if the path regex does not match" do
    @handler.send(:valid_upload?, {
      'CONTENT_LENGTH' => "10",
      'PATH_INFO' => '/spoons/',
      'REQUEST_METHOD' => 'POST',
      'QUERY_STRING' => "upload_id=#{@upload_id}"
    }).should == nil
  end
  
  it "should send a message to Mongrel::Uploads when calling upload_notify" do
    Mongrel::Uploads.should_receive(:add)
    @handler.send(:upload_notify, :add, @params)
  end
  
  it "should receive upload_notify with :add when the request begins" do
    @handler.should_receive(:upload_notify).with(:add, @params, 10)
    @handler.request_begins(@params)
  end
  
  it "should receive upload_notify with :mark when progress is checked" do
    @handler.should_receive(:upload_notify).with(:mark, @params, 7)
    @handler.request_progress(@params, 7, 10)
  end
  
  it "should receive upload_notify with :finish when ready to process the request" do
    @handler.should_receive(:upload_notify).with(:finish, @params)
    @handler.process(@request,@response)
  end
  
  it "should send Mongrel::Uploads :finish if the request is a valid upload" do
    Mongrel::Uploads.should_receive(:finish).with(@upload_id)
    @handler.stub!(:valid_upload?).and_return(@upload_id)
    @handler.request_aborted(@params)
  end
  
  it "should not send Mongrel::Uploads :finish unless the request is a valid upload" do
    Mongrel::Uploads.should_not_receive(:finish)
    @handler.stub!(:valid_upload?).and_return(false)
    @handler.request_aborted(@params)
  end
  
  it "should return an upload_id for a valid upload" do
    @handler.send(:valid_upload?, @params).should == @upload_id
  end
  
  it "should not consider a GET a valid upload" do
    @params['REQUEST_METHOD'] = 'GET'
    @handler.send(:valid_upload?, @params).should be_false
  end
  
  it "should consider a PUT a valid upload" do
    @params['REQUEST_METHOD'] = 'PUT'
    @handler.send(:valid_upload?, @params).should == @upload_id
  end
  
  it "should update Mongrel::Uploads' last checked time when calling upload_notify" do
    Mongrel::Uploads.should_receive(:update_checked_time).with(@upload_id)
    @handler.send(:upload_notify, :add, @params)
  end
  
  it "should not update Mongrel::Uploads' last checked time when calling upload_notify if the action is :finish" do
    Mongrel::Uploads.should_not_receive(:update_checked_time)
    @handler.send(:upload_notify, :finish, @params)
  end
  
  it "should not allow progress checks more frequently than the specified frequency" do
    Mongrel::Uploads.update_checked_time(@upload_id)
    @handler.request_progress(@params,7,10).should be_nil
  end
end