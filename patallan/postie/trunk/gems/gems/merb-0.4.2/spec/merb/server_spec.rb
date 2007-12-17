require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Server do
  it "should apply environment from the command line option --environment" do
    options = Merb::Server.merb_config(["--environment", "performance_testing"])
    options[:environment].should == "performance_testing"
  end

  it "should apply environment from the command line option -e" do
    options = Merb::Server.merb_config(["-e", "selenium"])
    options[:environment].should == "selenium"
  end
  
  it "should load the yaml file for the environment if it exists" do
    options = Merb::Server.merb_config(["-e", "environment_config_test"])
    options[:loaded_config_for_environment_config_test].should == true
  end

end
