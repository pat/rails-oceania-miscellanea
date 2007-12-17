require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "/<%= file_name %>/new" do
  before(:each) do
    @controller,@action = get("/<%= file_name %>/new")
    @body = @controller.body
  end

  it "should mention <%= class_name %>" do
    @body.should match(/<%= class_name %>/)
  end
end