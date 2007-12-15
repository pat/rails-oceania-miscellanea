require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "/suburbs" do
  before(:each) do
    @controller,@action = get("/suburbs")
    @body = @controller.body
  end

  it "should mention Suburbs" do
    @body.should match(/Suburbs/)
  end
end