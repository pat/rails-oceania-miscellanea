require File.dirname(__FILE__) + '/../spec_helper'
require 'strscan' #StringScanner

class ArticlePost; end

module FormControlsSpecHelper
  def setup_model_mock
    # NOTE Uses OpenStruct so we can see meaningful 
    #      class name to dom_id conversions.
    @model = OpenStruct.new({
      :title => "Chunky Bacon",
      :intro => "It's the tastiest kind.",
      :created_at => DateTime.parse("1963-11-22 12:30:00"),
      :published_at => Time.now,
      :version => 42,
      :secret => 'should not be shown'
    })
  end
end

describe Merb::FormControls, "All Form Fields", :shared => true do
  
  before do
    @opts ||= {}
  end
  
  it "should render css class if specified" do
    content = control_for( @model, :title, @control_type, :class => "TEST_CLASS" )
    content.should match( /class="TEST_CLASS"/)
  end
  
  it "should render default DOM id" do
    content = control_for(@model, :title, @control_type)
    content.should match(/id="open_struct_title"/)
  end
  
  it "should override default DOM id if passed as argument" do
    content = control_for(@model, :title, @control_type, :id => "porky")
    content.should match(/id="porky"/)
  end
  
  it "should override default DOM name if passed as argument" do
    content = control_for( @model, :title, @control_type, :name => "OVERRIDE")
    content.should match( /name="OVERRIDE"/ )
  end
  
  it "should render a label" do
    unless ( @opts[:skip_label] == true )
      content = control_for( @model, :title, @control_type, :label => "LABEL" )
      content.should match( /<label for="open_struct_title">LABEL<\/label>/)
    end
  end 
  
  it "should close the tag" do
    content = control_for( @model, @control_type, :password )
    content.clean.should match( /\/>\Z/ )
  end
  
  
  
end


describe Merb::FormControls, "text input" do
  include FormControlsSpecHelper

  it_should_behave_like "Merb::FormControls All Form Fields"
  
  before do
    setup_model_mock
    @control_type = :text
  end

  it "should render text input" do
    content = control_for(@model, :title, :text)
    content.should match(/type="text"/)
    content.should match(/value="Chunky Bacon"/)
    content.should match(/name="open_struct\[title\]"/)
  end

end


describe Merb::FormControls, "textarea" do
  include FormControlsSpecHelper

  it_should_behave_like "Merb::FormControls All Form Fields"

  before do
    setup_model_mock
    @control_type = :textarea
  end

  it "should render textarea" do
    content = control_for(@model, :intro, :textarea)
    content.should match(/textarea/)
    content.should match(/>It's the tastiest kind.</)
  end
  
end

describe Merb::FormControls, "number" do
  include FormControlsSpecHelper

  it_should_behave_like "Merb::FormControls All Form Fields"

  before do
    setup_model_mock
    @control_type = :number
  end

  it "should render number" do
    content = control_for(@model, :version, :number)
    content.should match(/value="42"/)
    content.should match(/type="text"/)
  end
  
end


describe Merb::FormControls, "hidden" do
  include FormControlsSpecHelper

  it_should_behave_like "Merb::FormControls All Form Fields"

  before do
    setup_model_mock
    @control_type = :hidden
    @opts = { :skip_label => true }
  end

  it "should render hidden field" do
    content = control_for(@model, :title, :hidden)
    content.should match(/value="Chunky Bacon"/)
    content.should match(/type="hidden"/)
  end
end


describe Merb::FormControls, "password" do
  include FormControlsSpecHelper

  it_should_behave_like "Merb::FormControls All Form Fields"

  before do
    setup_model_mock
    @control_type = :password
  end

  it "should render password field" do
    content = control_for( @model, :title, :password )
    content.should match( /<input/ )
    content.should match( /type="password"/ )
  end
  
  it "should not put any value into the field even if it is in the hash" do
    content = control_for( @model, :title, :password, :value => "OVERRIDE")
    content.should_not match( /value="OVERRIDE"/ )
  end

end


describe Merb::FormControls, "select" do
  include FormControlsSpecHelper
  
  it_should_behave_like "Merb::FormControls All Form Fields"

  before do
    setup_model_mock
    @control_type = :select
  end

  it "should render the select tag with the correct id and name" do
    content = control_for( @model, :version, :select )
    content.should match( /<select/ )
    content.should match( /id="open_struct_version"/ )
    content.should match( /name="open_struct\[version\]"/ )
    content.should match( /<\/select>/)
  end
  
  it "should include a blank option" do
    content = control_for( @model, :version, :select, :include_blank => true )
    content.should match( /<option><\/option>/ )
  end
  
  it "should render a select tag with options" do
    content = control_for( @model, :version, :select, :class => 'class1 class2', :title => 'This is the title' )
    content.should match( /class=\"class1 class2\"/)
    content.should match( /title=\"This is the title\"/ ) 
  end
  
  it "should render a select tag with options and a blank option" do
    content = control_for( @model, :version, :select, :title => "TITLE", :include_blank => true )
    content.should match( /title=\"TITLE\"/ ) 
    content.should match( /<option><\/option>/ )
  end
  
  it "should render the text as the value if no text_method is specified" do
    content = control_for( @model, :version, :select, :collection => [@model] )
    content.should match( /<option.*>42<\/option>/ )
  end
  
  it "should render a collection as option tags" do
    @model2 = OpenStruct.new({
      :version => 45
    })
    content = control_for( @model, :version, :select, :collection => [@model, @model2] )
    doc = Hpricot( content )
    (doc/"option").size.should == 2
    (doc/"option").should_not be_empty
    content.should match( /<option value="45">45<\/option>/ )
  end
  
  it "should select the object in the collection" do
    @model2 = @model2 = OpenStruct.new({
      :version => 45
    })
    content = control_for( @model, :version, :select, :collection => [@model, @model2] )
    content.should match( /<option selected="selected" value="42">42<\/option>/ )
  end
  
  it "should render a collection with a text method specified" do
    @model2 = OpenStruct.new({ :version => 45, :title => "TITLE" })
    content = control_for( @model, :version, :select, :collection => [@model, @model2], :text_method => :title )
    content.should match( /<option.*value="42".*>Chunky Bacon<\/option>.*<option.*value="45".*>TITLE<\/option/ )
  end  
  
  it "should render a hash of arrays as a grouped select box" do
    @model1 = OpenStruct.new({  :make   => "Ford",    :model  => "Mustang",   :code => 1 } )
    @model2 = OpenStruct.new({  :make   => "Ford",    :model  => "Falcon",    :code => 2 } )
    @model3 = OpenStruct.new({  :make   => "Holden",  :model  => "Comodore",  :code => 3 } )
    
    collection = [ @model1, @model2, @model3].group_by( &:make )
    
    content = control_for( @model1, :code, :select, :collection => collection, :text_method => :model )
    content.should match( /<optgroup label="Ford">/ )
    content.should match( /<option selected="selected" value="1">Mustang<\/option>/ )
    content.should match( /<option value="2">Falcon<\/option>/ )
    content.should match( /<optgroup label="Holden">/ )
    content.should match( /<option value="3">Comodore<\/option>/ )
    content.should match( /<\/optgroup>/)
  end
  
  it "should humanize and titlize keys in the label for the option group" do
    collection = { :some_snake_case_key => [@model] }
    content = control_for( @model, :version, :select, :collection => collection )
    content.should match( /<optgroup label="Some Snake Case Key">/ )
  end
  
end

describe Merb::FormControls, "time and date" do
  include FormControlsSpecHelper

  before(:each) do
    setup_model_mock
  end

  it "should render time" do
    content = control_for(@model, :created_at, :time)
    content.should match(/<select .*\[created_at\]\[day\]/)
    content.should match(/<select .*\[created_at\]\[month\]/)
    content.should match(/<select .*\[created_at\]\[year\]/)
    content.should match(/<select .*\[created_at\]\[hour\]/)
    content.should match(/<select .*\[created_at\]\[minute\]/)
    content.should match(/<select .*\[created_at\]\[second\]/)
  end
  
  it "should render date" do
    content = control_for(@model, :created_at, :date)
    content.should match(/<select .*\[created_at\]\[day\]/)
    content.should match(/<select .*\[created_at\]\[month\]/)
    content.should match(/<select .*\[created_at\]\[year\]/)
    content.should_not match(/<select .*\[created_at\]\[hour\]/)
    content.should_not match(/<select .*\[created_at\]\[minute\]/)
    content.should_not match(/<select .*\[created_at\]\[second\]/)
  end

  it "should select objects time" do
    content = control_for(@model, :created_at, :time)
    s = StringScanner.new(content)
    part = s.scan_until(/<\/select>/)
    part.should match(/day/)
    part.should match(/selected="selected" value="#{@model.created_at.day}"/)
    part = s.scan_until(/<\/select>/)
    part.should match(/month/)
    part.should match(/selected="selected" value="#{@model.created_at.month}"/)
    part = s.scan_until(/<\/select>/)
    part.should match(/year/)
    part.should match(/selected="selected" value="#{@model.created_at.year}"/)
    part = s.scan_until(/<\/select>/)
    part.should match(/hour/)
    part.should match(/selected="selected" value="#{@model.created_at.hour}"/)
    part = s.scan_until(/<\/select>/)
    part.should match(/minute/)
    part.should match(/selected="selected" value="#{@model.created_at.min}"/)
    part = s.scan_until(/<\/select>/)
    part.should match(/second/)
    part.should match(/selected="selected" value="#{@model.created_at.sec}"/)
  end

  it "should default to 1950..2050" do 
    content = control_for(@model, :created_at, :date)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[year\]/
    part = s.scan_until(/<\/select>/)
    part.should_not match(/>1949<\/option>/)
    part.should     match(/>1950<\/option>/)
    part.should     match(/>2050<\/option>/)
    part.should_not match(/>2051<\/option>/)
  end

  it "should accept min_year" do
    content = control_for(@model, :created_at, :date, :min_year => 1980)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[year\]/
    part = s.scan_until(/<\/select>/)
    part.should_not match(/>1979<\/option>/)
    part.should     match(/>1980<\/option>/)
    part.should     match(/>2050<\/option>/)
    part.should_not match(/>2051<\/option>/)
  end
 
 it "should accept max_year" do
    content = control_for(@model, :created_at, :date, :max_year => 2010)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[year\]/
    part = s.scan_until(/<\/select>/)
    part.should_not match(/>1949<\/option>/)
    part.should     match(/>1950<\/option>/)
    part.should     match(/>2010<\/option>/)
    part.should_not match(/>2011<\/option>/)
  end

  it "should accept min_year and max_year" do
    content = control_for(@model, :created_at, :date, :min_year => 1980, :max_year => 2010)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[year\]/
    part = s.scan_until(/<\/select>/)
    part.should_not match(/>1979<\/option>/)
    part.should     match(/>1980<\/option>/)
    part.should     match(/>2010<\/option>/)
    part.should_not match(/>2011<\/option>/)
  end
  
  it "should render a label for date" do
    content = control_for( @model, :created_at, :date, :label => "LABEL" )
    content.should match( /<label for="open_struct_created_at">LABEL<\/label>/)
  end
  
  it "should render a label for time" do
    content = control_for( @model, :created_at, :time, :label => "LABEL" )
    content.should match( /<label for="open_struct_created_at">LABEL<\/label>/)
  end
end
  

describe Merb::FormControls, "Missing time and day" do 

  before do
    @post = OpenStruct.new(
      :stringdate => "",
      :stringtime => "",
      :nildate => nil,
      :niltime => nil
      )
  end

  it "should handle date as string" do
    control_for(@post, :stringdate, :date)
  end

  it "should handle time as string" do
    control_for(@post, :stringtime, :time)
  end

  it "should handle date as nil" do
    control_for(@post, :nildate, :date)
  end

  it "should handle time as nil" do
    control_for(@post, :niltime, :time)
  end
end


describe Merb::FormControls, "monthnames" do
  include FormControlsSpecHelper
  
  before do
    setup_model_mock
  end

  it "should include default monthnames" do
    content = control_for(@model, :created_at, :date, :monthnames => true)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[month\]/
    part = s.scan_until(/<\/select>/)
    (1..12).each do |m|
      if m == @model.created_at.month
        part.should match(/selected="selected" value="#{m}"\>#{Date::MONTHNAMES[m]}/)
      else
        part.should match(/value="#{m}"\>#{Date::MONTHNAMES[m]}/)
      end
    end
    part.should_not match(/value="0"/)
    part.should_not match(/value="13"/)
  end

  it "should include custom monthnames" do
    french_months = [nil] + %w(janvier février mars avril mai juin 
                               juillet août septembre octobre novembre décembre)
    content = control_for(@model, :created_at, :date, :monthnames => french_months)
    s = StringScanner.new(content)
    s.skip_until /<select .*\[created_at\]\[month\]/
    part = s.scan_until(/<\/select>/)
    (1..12).each do |m|
      if m == @model.created_at.month
        part.should match(/selected="selected" value="#{m}"\>#{french_months[m]}/)
      else
        part.should match(/value="#{m}"\>#{french_months[m]}/)
      end
    end
    part.should_not match(/value="0"/)
    part.should_not match(/value="13"/)
  end
end



