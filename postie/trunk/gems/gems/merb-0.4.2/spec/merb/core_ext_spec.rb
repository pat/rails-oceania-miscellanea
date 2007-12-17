require File.dirname(__FILE__) + '/../spec_helper'

describe "A Numeric object" do

  it "should be able to convert to US currency" do
    1.5.to_currency.should == "$1.50"
  end

  it "should be able to convert to Danish currency" do
    15_000_000.5.to_currency(nil, ".", ",", "DM").should == "15.000.000,50DM"
  end

  {
    :microsecond => Float(10 ** -6), :millisecond => Float(10 ** -3), :second => 1,
    :minute => 60, :hour => 3600, :day => 86400, :week => 604800,
    :month => 2592000, :year => 31536000, :decade => 315360000
  }.each do |method,seconds|

    it "should be able to convert to #{method}s (singular version)" do
      1.send(method).should == seconds
    end

    it "should be able to convert to #{method}s (plural version)" do
      2.send("#{method}s").should == seconds * 2
    end

  end

end

class MyString < String; end
class String
  def self.define_meta meth, val
    meta_def meth do; val; end
  end
end

describe "An object" do

  it "should be able to return a passed in object that is modified by a block" do
    (returning({}) {|x| x.merge!(:foo => :bar)}).should == {:foo => :bar}
  end

  it "should be able to get a meta class" do
    MyString.meta_class.to_s.should == "#<Class:MyString>"
  end

  it "should be able to execute code in the meta-class' context" do
    (MyString.meta_eval { self }).should == MyString.meta_class
  end

  it "should be able to define a method on the meta-class" do
    MyString.define_meta :foo, :bar
    MyString.foo.should == :bar
  end

  it "should be able to define methods on its instances" do
    MyString.class_def :foo do; :bar; end
    MyString.new.foo.should == :bar
  end

  {[] => true,
   [1] => false,
   [nil] => false,
   nil => true,
   true => false,
   false => true,
   "" => true,
   "   " => true,
   "  hey " => false
  }.each do |obj, expected|
    it "should be able to determine whether the #{obj.class} #{obj.inspect} is blank" do
      obj.blank?.should == expected
    end
  end
end

describe Enumerable do

  before do
    @mascots = ['louie', 'bert', 'ernie']
  end

  it "should perform injecting" do
    @mascots.injecting({}){|m,i| m[i] = i.size }.should == 
         {'louie'=>5, 'bert'=>4, 'ernie'=>5} 
  end  

  it "should find arrays of things inside other arrays" do
    @mascots.include_any?('louie', 'sasquatch').should be_true
  end

  it "should recognize absence of arrays of things inside other arrays" do
    @mascots.include_any?('chicken', 'sasquatch').should be_false
  end

  it "should group by" do
    groups = (1..6).group_by{|i| i%3}
    groups[0].should == [3,6]
    groups[1].should == [1,4]
    groups[2].should == [2,5]
  end

end

describe Symbol do

  it "should be able to call Symbol#to_proc" do
    ['foo', 'bar'].map(&:reverse).should == ['oof', 'rab']
  end
  
end

# Class cattr_reader

class ClassWithCAttrReader
  cattr_reader      :bacon
  def initialize;   @@bacon = "chunky";   end
end

describe "Core Class with cattr_reader", :shared => true do

  it "should read value from attribute" do
    @klass.bacon.should == "chunky"
  end

  it "should not write to attribute" do
    lambda {
      @klass.bacon = "soggy"
    }.should raise_error(NoMethodError)
  end

end

describe Class, "with cattr_reader" do

  before do
    @klass = ClassWithCAttrReader.new.class
  end
  it_should_behave_like "Core Class with cattr_reader"

end

describe Class, "with cattr_reader (instantiated)" do

  before do
    @klass = ClassWithCAttrReader.new
  end
  it_should_behave_like "Core Class with cattr_reader"

end

# Class cattr_writer

class ClassWithCAttrWriter
  cattr_writer      :bacon
  def self.chunky?; @@bacon == "chunky";  end
  def chunky?;      self.class.chunky?;   end
end

describe "Core Class with cattr_writer", :shared => true do

  it "should write value to attribute" do
    @klass.should be_chunky
  end

  it "should not read attribute" do
    lambda {
      @klass.bacon
    }.should raise_error(NoMethodError)
  end

end

describe Class, "with cattr_writer" do

  before do
    @klass = ClassWithCAttrWriter.new.class
    @klass.bacon = "chunky"
  end
  it_should_behave_like "Core Class with cattr_writer"

end

describe Class, "with cattr_writer (instantiated)" do

  before do
    @klass = ClassWithCAttrWriter.new
    @klass.bacon = "chunky"
  end
  it_should_behave_like "Core Class with cattr_writer"

end

describe Hash, "environmentize_keys!" do
  it "should transform keys to uppercase text" do
    { :test_1  => 'test', 'test_2' => 'test', 1 => 'test'}.environmentize_keys!.should ==
    { 'TEST_1' => 'test', 'TEST_2' => 'test', '1' => 'test'}
  end
  
  it "should only transform one level of keys" do
    { :test_1  => { :test2 => 'test'}}.environmentize_keys!.should == 
    { 'TEST_1' => { :test2 => 'test'}}
  end
end

describe Hash, "to_xml_attributes" do
  
  before do
    @hash = { :one => "ONE", "two" => "TWO" }
  end
  
  it "should turn the hash into xml attributes" do
    attrs = @hash.to_xml_attributes
    attrs.should match( /one="ONE"/m )
    attrs.should match( /two="TWO"/m )
  end
  
end

describe Hash, "from_xml" do

  it "should transform a simple tag with content" do
    xml = "<tag>This is the contents</tag>"
    Hash.from_xml( xml ).should == { 'tag' => 'This is the contents' }
  end
  
  it "should transform a simple tag with attributes" do
    xml = "<tag attr1='1' attr2='2'></tag>"
    Hash.from_xml( xml ).should == { 'tag' => {
                                                'attr1' => '1',
                                                'attr2' => '2'
                                                }}
  end  
  
  it "should transform repeating siblings into an array" do
    xml =<<-XML
      <opt>
        <user login="grep" fullname="Gary R Epstein" />
        <user login="stty" fullname="Simon T Tyson" />
      </opt>
    XML

    Hash.from_xml( xml )['opt']['user'].should be_an_instance_of( Array )
    
    Hash.from_xml( xml ).should =={ 'opt' => {'user' => [{
                                                  'login'    => 'grep',
                                                  'fullname' => 'Gary R Epstein'
                                                },{
                                                  'login'    => 'stty',
                                                  'fullname' => 'Simon T Tyson'
                                                }]
                                  }}

  end
  
  it "should not transform non-repeating siblings into an array" do
    xml =<<-XML
      <opt>
        <user login="grep" fullname="Gary R Epstein" />
      </opt>
    XML
      
    Hash.from_xml( xml )['opt']['user'].should be_an_instance_of( Hash )
    
    Hash.from_xml( xml ).should == { 'opt' => { 
                                        'user' => { 
                                          'login' => 'grep', 
                                          'fullname' => 'Gary R Epstein'
                                        }
                                      }}
  end
  
  it "should typecast an integer" do
    xml = "<tag type='integer'>10</tag>"
    Hash.from_xml(xml)['tag'].should == 10
  end
  
  it "should typecast a true boolean" do
    xml = "<tag type='boolean'>true</tag>"
    Hash.from_xml( xml )['tag'].should be_true
  end
  
  it "should typecast a false boolean" do
    ["false", "1", "0", "some word" ].each do |w|
      Hash.from_xml( "<tag type='boolean'>#{w}</tag>" )['tag'].should be_false
    end
  end
  
  it "should typecast a datetime" do
    xml = "<tag type='datetime'>2007-12-31 10:32</tag>"
    Hash.from_xml( xml )['tag'].should == Time.parse( '2007-12-31 10:32' ).utc
  end
  
  it "should typecast a date" do
    xml = "<tag type='date'>2007-12-31</tag>"
    Hash.from_xml( xml )['tag'].should == Date.parse( '2007-12-31' )
  end
  
  it "should unescape html entities" do
    values = {
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      "'" => "&apos;",
      "&" => "&amp;"
    }
    values.each do |k,v|
      xml = "<tag>Some content #{v}</tag>"
      Hash.from_xml( xml )['tag'].should match( Regexp.new( k ) )
    end
  end
  
  it "should undasherize keys as tags" do
    xml = "<tag-1>Stuff</tag-1>"
    Hash.from_xml( xml ).keys.should include( 'tag_1' )
  end
  
  it "should undasherize keys as attributes" do
    xml = "<tag1 attr-1='1'></tag1>"
    Hash.from_xml( xml )['tag1'].keys.should include( 'attr_1')
  end
  
  it "should undasherize keys as tags and attributes" do
    xml = "<tag-1 attr-1='1'></tag-1>"
    Hash.from_xml( xml ).keys.should include( 'tag_1' )
    Hash.from_xml( xml )['tag_1'].keys.should include( 'attr_1')
  end
  
  it "should render nested content correctly" do
    xml = "<root><tag1>Tag1 Content <em><strong>This is strong</strong></em></tag1></root>"
    Hash.from_xml( xml )['root']['tag1'].should == "Tag1 Content <em><strong>This is strong</strong></em>"
  end
  
  it "should render nested content with split text nodes correctly" do
    xml = "<root>Tag1 Content<em>Stuff</em> Hi There</root>"
    Hash.from_xml( xml )['root'].should == "Tag1 Content<em>Stuff</em> Hi There"
  end
  
  it "should ignore attributes when a child is a text node" do
    xml = "<root attr1='1'>Stuff</root>"
    Hash.from_xml( xml ).should == { "root" => "Stuff" }
  end
  
  it "should ignore attributes when any child is a text node" do
    xml = "<root attr1='1'>Stuff <em>in italics</em></root>"
    Hash.from_xml( xml ).should == { "root" => "Stuff <em>in italics</em>" }
  end
  
  it "should correctly transform multiple children" do
    xml = <<-XML
    <user gender='m'>
      <age type='integer'>35</age>
      <name>Home Simpson</name>
      <dob type='date'>1988-01-01</dob>
      <joined-at type='datetime'>2000-04-28 23:01</joined-at>
      <is-cool type='boolean'>true</is-cool>
    </user>
    XML
    Hash.from_xml( xml ).should == { "user" => 
                                        { "gender"    => "m",
                                          "age"       => 35,
                                          "name"      => "Home Simpson",
                                          "dob"       => Date.parse( '1988-01-01' ),
                                          "joined_at" => Time.parse( "2000-04-28 23:01"),
                                          "is_cool"   => true 
                                        }
                                    }
  end
  
  
  
end

class ClassWithAttrInitialize
  attr_initialize :dog, :muppet
  attr_accessor   :dog, :muppet
end

describe ClassWithAttrInitialize do

  it "should initialize with values" do
    c = ClassWithAttrInitialize.new("louie", "bert")
    c.dog.should    == "louie"
    c.muppet.should == "bert"
  end

end

describe "A String" do
  it "should convert a path/like/this to a Constant::String::Like::This" do
    "path/like/this".to_const_string.should == "Path::Like::This"
    "path".to_const_string.should == "Path"
    "snake_case/path/with_several_parts".to_const_string.should == "SnakeCase::Path::WithSeveralParts"
  end
  
  it "should raise an error rather than freeze when trying to convert bad Paths/12Like/-this" do
    Timeout::timeout(1) do
      lambda do
        "Paths/12Like/-this".to_const_string
      end.should raise_error(String::InvalidPathConversion)
    end.should_not raise_error(Timeout::Error)
  end

  it "should remove any indentation and add +indentation+ number of spaces" do
    "foo\n  bar\n".indent(3).should == "   foo\n     bar\n"
    "  foo\n    bar\n".indent(3).should == "   foo\n     bar\n"
  end
end

describe "extracting options from arguments" do
  
  def the_method(*args)
    [extract_options_from_args!(args),args]
  end
  
  it "should extract the hash if the last item is a hash" do
    opts,args = the_method(:one, :two, :key => :value)
    opts.should == {:key => :value}
    args.should == [:one, :two]
  end
  
  it "should return nil for the opts if no hash is provided" do
    opts,args = the_method(:one, :two)
    opts.should be_nil
    args.should == [:one, :two]
  end
  
  it "should return two hashes" do
    opts,args = the_method( {:one => :two}, :key => :value)
    opts.should == {:key => :value}
    args.should == [{:one => :two}]
  end
  
end

describe Inflector do
  it "should transform words from singular to plural" do
    "post".pluralize.should == "posts"
    "octopus".pluralize.should =="octopi"
    "the blue mailman".pluralize.should == "the blue mailmen"
    "CamelOctopus".pluralize.should == "CamelOctopi"
  end
  it "should transform words from plural to singular" do
    "posts".singularize.should == "post"
    "octopi".singularize.should == "octopus"
    "the blue mailmen".singularize.should == "the blue mailman"
    "CamelOctopi".singularize.should == "CamelOctopus"
  end
  it "should transform class names to table names" do
    "RawScaledScorer".tableize.should == "raw_scaled_scorers"
    "egg_and_ham".tableize.should == "egg_and_hams"
    "fancyCategory".tableize.should == "fancy_categories"
  end
  it "should tranform table names to class names" do
    "egg_and_hams".classify.should == "EggAndHam"
    "post".classify.should == "Post"    
  end
  it "should create a foreign key name from a class name" do
    "Message".foreign_key.should == "message_id"
    "Message".foreign_key(false).should == "messageid"
    "Admin::Post".foreign_key.should == "post_id"  
  end
end
