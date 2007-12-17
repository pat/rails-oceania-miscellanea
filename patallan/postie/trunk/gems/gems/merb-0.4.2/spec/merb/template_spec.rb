require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Template do
  
  it "should register the extensions for a given engine" do
    Merb::Template::EXTENSIONS["tester_ext"].should be_nil
    Merb::Template::EXTENSIONS["ext"].should be_nil
    Merb::Template.register_extensions(:tester, %w[tester_ext ext])
    Merb::Template::EXTENSIONS["tester_ext"].should == :tester
    Merb::Template::EXTENSIONS["ext"].should == :tester
  end
  
  it "should raise an error when registering extensions if the engine is not a symbol" do
    lambda do
      Merb::Template.register_extensions("tester", %w(thing))
    end.should raise_error(ArgumentError)
  end
  
  it "should raise an error when registering extensions if the extensions are not an array" do
    lambda do
      Merb::Template.register_extensions(:tester, "tester")
    end.should raise_error(ArgumentError)
  end
  
  it "should select the engine for an erubis file" do
    Merb::Template.engine_for("test.html.erb").should == Merb::Template::Erubis
  end
  
  it "should select the engine for an haml file" do
    Merb::Template.engine_for("test.html.haml").should == Merb::Template::Haml
  end
  
  it "should select the engine for a markaby file" do
    Merb::Template.engine_for("test.html.mab").should == Merb::Template::Markaby    
  end
  
  it "should select the builder engine" do
    Merb::Template.engine_for("test.xml.builder").should == Merb::Template::XMLBuilder    
  end
  
end