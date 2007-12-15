require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Postcodes Controller", "index action" do
  before(:each) do
    @controller = Postcodes.build(fake_request)
    @controller.dispatch('index')
  end
  
  it "should query the Localities for items with matching postcodes" do
    #
  end
  
  it "should respond to HTML requests" do
    #
  end
  
  it "should respond to JSON requests" do
    #
  end
  
  it "should respond to XML requests" do
    #
  end
end