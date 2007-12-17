require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Config do
  before(:all) do
    @config_yml = File.expand_path(File.dirname(__FILE__) / ".." / "fixtures")
  end
  
  it "should have a default configuration" do
    Merb::Config.defaults.should be_is_a(Hash)
    Merb::Config.defaults[:merb_root].should == Dir.pwd
  end
  
  it "should not load the config.yml file if it does not exist" do
    Merb::Config.setup.should be_is_a(Hash)
    Merb::Config.setup.should == Merb::Config.defaults
  end
  
  it "should load the config.yml file if it exists" do
    Merb::Config.defaults.merge!(:merb_root => @config_yml)
    Merb::Config.setup.should be_is_a(Hash)
    Merb::Config.setup[:host].should == "127.0.0.1"
  end

  it "should accept erb in the config.yml file" do
    Merb::Config.defaults.merge!(:merb_root => @config_yml)
    Merb::Config.setup.should be_is_a(Hash)
    Merb::Config.setup[:environment].should == "test"
  end
end