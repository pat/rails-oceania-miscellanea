require File.dirname(__FILE__) + '/../spec_helper'

describe "View Context", "image tag" do
  
  include Merb::ViewContextMixin
  it "should render an link" do
    the_link = link_to( "NAME", "http://example.com", :title => "TITLE", :target => "TARGET" )
    the_link.should match( /<a.+>NAME<\/a>/ )
    the_link.should match( /href="http:\/\/example.com"/)
    the_link.should match( /title="TITLE"/)
    the_link.should match( /target="TARGET"/ )    
  end

  it "should render local image" do
    image_tag('foo.gif').clean.should == %[<img src="/images/foo.gif"/>].clean
  end

  it "should render a local image with a path_prefix" do
    Merb::Server.config[:path_prefix] = '/inky'
    image_tag('foo.gif').clean.should == %[<img src="/inky/images/foo.gif"/>].clean
    Merb::Server.config.delete(:path_prefix)
  end
  
  it "should render local image with class" do
    image_tag('foo.gif', :class => 'bar').clean.should == %[<img src="/images/foo.gif" class="bar" />].clean
  end

  it "should render local image with class and explicit path" do
    image_tag('foo.gif', :class => 'bar', :path => '/files/').clean.should == %[<img src="/files/foo.gif" class="bar" />].clean
  end

  it "should render remote image" do
    image_tag('http://test.com/foo.gif').clean.should == %[<img src="http://test.com/foo.gif"/>].clean    
  end

  it "should render remote SSL image" do
    image_tag('https://test.com/foo.gif').clean.should == %[<img src="https://test.com/foo.gif"/>].clean
  end

end

describe "View Context", "css tag" do
  
  include Merb::ViewContextMixin
  
  it "should render a link tag with the css_include_tag method" do
    css_include_tag('foo.css').clean.should ==
    %[<link href="/stylesheets/foo.css" media="all" rel="Stylesheet" type="text/css"/>].clean

    css_include_tag('foo').should == css_include_tag('foo.css')

    css_include_tag('foo', 'bar').should ==
    css_include_tag('foo') +
    css_include_tag('bar')
  end
  
  it "should render a link tag with a path_prefix" do
    Merb::Server.config[:path_prefix] = '/inky'
    css_include_tag('foo.css').clean.should ==
      %[<link href="/inky/stylesheets/foo.css" media="all" rel="Stylesheet" type="text/css"/>].clean
    Merb::Server.config.delete(:path_prefix)
  end
  
  it "should not generate a script tag with the include_required_css" do
    include_required_css.clean.should == ''
  end
  
  it "should generate script tags with the include_required_css" do
    require_css('foo')
    require_css('bar')
    include_required_css.should ==
      css_include_tag('foo') + css_include_tag('bar')
  end
end

describe "View Context", "script tag" do
  
  include Merb::ViewContextMixin
  
  it "should render a script tag with the js_include_tag method" do
    js_include_tag('foo.js').clean.should == %[<script src="/javascripts/foo.js" type="text/javascript">//</script>].clean

    js_include_tag('foo').should == js_include_tag('foo.js')

    js_include_tag('foo', 'bar').should ==
    js_include_tag('foo') +
    js_include_tag('bar')
  end
  
  it "should render a script tag with a path_prefix" do
    Merb::Server.config[:path_prefix] = '/inky'
    js_include_tag('foo.js').clean.should ==
      %[<script src="/inky/javascripts/foo.js" type="text/javascript">//</script>].clean
    Merb::Server.config.delete(:path_prefix)
  end
  
  it "should not generate a script tag with the include_required_js" do
    include_required_js.clean.should == ''
  end
  
  it "should generate script tags with the include_required_js" do
    require_js('foo')
    require_js('bar')
    include_required_js.should == js_include_tag('foo') + js_include_tag('bar')
  end
end

describe "View Context", "throw_content, catch_content" do
  
  include Merb::ViewContextMixin
  
  it "should throw content" do
    c = new_controller
    content = c.render :template => "examples/template_throw_content", :layout => :none
    content.should match( /THROWN CONTENT/m )
  end

  it "should throw content including a partial" do
    c = new_controller
    content = c.render :template => "examples/template_catch_content_from_partial", :layout => :none
    content.should match( /CONTENT THROWN FROM PARTIAL/m )
  end

  it "should catch content" do
    c = new_controller
    content = c.render :template => "examples/template_catch_content", :layout => :none
    content.should match( /CAUGHT CONTENT/m)
  end
  
  it "should catch content with multiple throws" do
    c = new_controller
    content = c.render :template => "examples/template_catch_content", :layout => :none
    content.should match( /CAUGHT FOOTER/m )
    content.should match( /START FOOTER\s+CAUGHT FOOTER\s+END FOOTER/m )
  end
  
  it "should not render the block inline" do
    c = new_controller
    content = c.render :template => "examples/template_catch_content", :layout => :none
    content.should match( /\A\s*START HEADER\s*CAUGHT CONTENT\s*END HEADER\s*START FOOTER\s*CAUGHT FOOTER\s*END FOOTER\s*\Z/m)
  end

  it "should throw content as an argument without a block" do
    c = new_controller
    content = c.render :template => "examples/template_throw_content_without_block", :layout => :none
    content.should match(/Content Without Block/)
  end
end

describe Merb::ViewContextMixin do

  it "should render the start of a tag" do
    open_tag(:div).should == "<div>"
  end
  
  it "should render the start of a tag with attributes" do
    tag = open_tag(:div, :id => 1, :class => "CLASS")
    tag.should match( /^<div /)
    tag.should match( /id="1"/)
    tag.should match( /class="CLASS"/)
    tag.should match( />$/ )
  end
  
  it "should render a self closing tag" do
    self_closing_tag( :br ).should == "<br/>"
  end
  
  it "should render a self closing tag with attributes" do
    self_closing_tag(:img, :src => "SOURCE" ).should == "<img src=\"SOURCE\"/>"
  end
  
  it "should render a closing tag" do
    close_tag(:div).should == "</div>"
  end
    
end
