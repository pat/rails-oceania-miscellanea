require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "/<%= file_name %>" do
  before(:each) do
    @controller,@action = get("/<%= file_name %>")
    @body = @controller.body
  end

  it "should mention <%= class_name %>" do
    @body.should match(/<%= class_name %>/)
  end
end