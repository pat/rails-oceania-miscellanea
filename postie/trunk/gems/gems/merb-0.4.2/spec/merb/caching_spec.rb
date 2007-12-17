require File.dirname(__FILE__) + '/../spec_helper'

describe "all fragment caching", :shared => true do

  it "should be able to store and retrieve a key" do
    @c.put(:foo, "Bar")
    @c.get(:foo).should == "Bar"
  end
  
  it "should be able to expire a fragment" do
    @c.put(:foo, "Bar")
    @c.get(:foo).should == "Bar"
    @c.expire_fragment(:foo)
    @c.get(:foo).should == nil
  end  
  
  it "should clear the cache on reset" do
    @c.put(:foo, "Bar")
    @c.get(:foo).should == "Bar"
    @c.clear
    @c.get(:foo).should == nil
  end
  
  it "should be ok to clear the cache twice" do
    @c.clear
    @c.clear
  end
  
  it "should accept keys and subkeys" do
    @c.put([:user, :joe], "Joe's data")
    @c.get([:user, :joe]).should. == "Joe's data"
  end
  
  it "should keep subkeys separate" do
    @c.put([:user, :joe], "Joe's data")
    @c.put([:user, :bill], "Bill's data")
    @c.get([:user, :joe]).should == "Joe's data"
    @c.get([:user, :bill]).should == "Bill's data"
  end
  
  it "should expire a subkey" do
    @c.put([:user, :joe], "Joe's data")
    @c.put([:user, :bill], "Bill's data")
    @c.expire_fragment([:user,:joe])
    @c.get([:user, :joe]).should == nil
    @c.get([:user, :bill]).should == "Bill's data"
  end
  
  it "should expire a key and all its children when passed an array containing only the top key" do
    @c.put([:user, :joe], "Joe's data")
    @c.put([:user, :bill], "Bill's data")
    @c.expire_fragment([:user])
    @c.get([:user, :joe]).should == nil
    @c.get([:user, :bill]).should == nil
  end
    
  it "should expire a key and all its children when passed only the top key" do
    @c.put([:user, :joe], "Joe's data")
    @c.put([:user, :bill], "Bill's data")
    @c.expire_fragment(:user)
    @c.get([:user, :joe]).should == nil
    @c.get([:user, :bill]).should == nil
  end
  
  it "should handle arbitrary levels of keys" do
     @c.put([:users, :show, :bob], "Bob's data")
     @c.put([:users, :show, :mary], "Mary's data")
     @c.put([:users, :edit, :bob], "Bob's editable data")
     @c.get([:users, :show, :bob]).should == "Bob's data"
     @c.get([:users, :edit, :bob]).should == "Bob's editable data"
     @c.expire_fragment([:users, :show, :mary])
     @c.get([:users, :show, :mary]).should == nil
     @c.get([:users, :show, :bob]).should == "Bob's data"     
     @c.expire_fragment([:users, :show])
     @c.get([:users, :show, :bob]).should == nil
     @c.expire_fragment([:users])
     @c.get([:users, :edit, :bob]).should == nil
   end  
    
  
end


describe "fragment caching in memory" do
  before do
    Merb::Server.config['cache_store'] = 'memory'
    @c = Merb::Caching::Fragment
    @c.clear
  end

  it_should_behave_like "all fragment caching"
end

describe "fragment caching to a file" do
  before do
    Merb::Server.config[:cache_store] = 'file'
    @c = Merb::Caching::Fragment
    @c.clear
  end

  it_should_behave_like "all fragment caching"
end
