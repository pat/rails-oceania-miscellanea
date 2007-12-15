require File.join(File.dirname(__FILE__),'..','..','spec_helper')

describe "/postcodes" do
  before(:each) do
    @controller,@action = get("/postcodes")
    @body = @controller.body
  end

  it "should mention Postcodes" do
    @body.should match(/Postcodes/)
  end
end