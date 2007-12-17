module Merb
  # The ViewContextMixin module provides a number of helper methods to views for
  # linking to assets and other pages, dealing with JavaScript, and caching.
  module ViewContextMixin
    # :section: Accessing Assets
    # Merb provides views with convenience methods for links images and other assets.
    
    # Creates a link for the URL given in +url+ with the text in +name+; HTML options are given in the +opts+
    # hash.
    #
    # ==== Options
    # The +opts+ hash is used to set HTML attributes on the tag.
    #    
    # ==== Examples
    #   link_to("The Merb home page", "http://www.merbivore.com/")
    #   # => <a href="http://www.merbivore.com/">The Merb home page</a>
    #
    #   link_to("The Ruby home page", "http://www.ruby-lang.org", {'class' => 'special', 'target' => 'blank'})
    #   # => <a href="http://www.ruby-lang.org" class="special" target="blank">The Ruby home page</a>
    #
    #   link_to p.title, "/blog/show/#{p.id}"
    #   # => <a href="blog/show/13">The Entry Title</a>
    #
    def link_to(name, url='', opts={})
      opts[:href] ||= url
      %{<a #{ opts.to_xml_attributes }>#{name}</a>}
    end
  
    # Creates an image tag with the +src+ attribute set to the +img+ argument.  The path
    # prefix defaults to <tt>/images/</tt>.  The path prefix can be overriden by setting a +:path+
    # parameter in the +opts+ hash.  The rest of the +opts+ hash sets HTML attributes.
    #
    # ==== Options
    # path:: Sets the path prefix for the image (defaults to +/images/+)
    # 
    # All other options in +opts+ set HTML attributes on the tag.
    #
    # ==== Examples
    #   image_tag('foo.gif') 
    #   # => <img src='/images/foo.gif' />
    #   
    #   image_tag('foo.gif', :class => 'bar') 
    #   # => <img src='/images/foo.gif' class='bar' />
    #
    #   image_tag('foo.gif', :path => '/files/') 
    #   # => <img src='/files/foo.gif' />
    #
    #   image_tag('http://test.com/foo.gif')
    #   # => <img src="http://test.com/foo.gif">
    def image_tag(img, opts={})
      opts[:path] ||= 
        if img =~ %r{^https?://}
          ''
        else
          if Merb::Server.config[:path_prefix]
            Merb::Server.config[:path_prefix] + '/images/'
          else
            '/images/'
          end
        end
      opts[:src] ||= opts.delete(:path) + img
      %{<img #{ opts.to_xml_attributes } />}    
    end

    # :section: JavaScript related functions
    #
    
    # Escapes text for use in JavaScript, replacing unsafe strings with their
    # escaped equivalent.
    #
    # ==== Examples
    #   escape_js("'Lorem ipsum!' -- Some guy")
    #   # => "\\'Lorem ipsum!\\' -- Some guy"
    #
    #   escape_js("Please keep text\nlines as skinny\nas possible.")
    #   # => "Please keep text\\nlines as skinny\\nas possible."
    def escape_js(javascript)
      (javascript || '').gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
    end
    
    # Creates a link tag with the text in +name+ and the <tt>onClick</tt> handler set to a JavaScript 
    # string in +function+.
    #
    # ==== Examples
    #   link_to_function('Click me', "alert('hi!')")
    #   # => <a href="#" onclick="alert('hi!'); return false;">Click me</a>
    #
    #   link_to_function('Add to cart', "item_total += 1; alert('Item added!');")
    #   # => <a href="#" onclick="item_total += 1; alert('Item added!'); return false;">Add to cart</a>
    #   
    def link_to_function(name, function)
      %{<a href="#" onclick="#{function}; return false;">#{name}</a>}
    end
    
    # The js method simply calls +to_json+ on an object in +data+; if the object
    # does not implement a +to_json+ method, then it calls +to_json+ on 
    # +data.inspect+.
    #
    # ==== Examples
    #   js({'user' => 'Lewis', 'page' => 'home'})
    #   # => "{\"user\":\"Lewis\",\"page\":\"home\"}"
    #
    #   my_array = [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
    #   js(my_array)
    #   # => "[1,2,{\"a\":3.141},false,true,null,\"4..10\"]"
    #
    def js(data)
      if data.respond_to? :to_json
        data.to_json
      else
        data.inspect.to_json
      end
    end
      
    # :section: External JavaScript and Stylesheets
    #
    # You can use require_js(:prototype) or require_css(:shinystyles)
    # from any view or layout, and the scripts will only be included once
    # in the head of the final page. To get this effect, the head of your layout you will
    # need to include a call to include_required_js and include_required_css.
    #
    # ==== Examples
    #   # File: app/views/layouts/application.html.erb
    #
    #   <html>
    #     <head>
    #       <%= include_required_js %>
    #       <%= include_required_css %>
    #     </head>
    #     <body>
    #       <%= catch_content :layout %>
    #     </body>
    #   </html>
    # 
    #   # File: app/views/whatever/_part1.herb
    #
    #   <% require_js  'this' -%>
    #   <% require_css 'that', 'another_one' -%>
    # 
    #   # File: app/views/whatever/_part2.herb
    #
    #   <% require_js 'this', 'something_else' -%>
    #   <% require_css 'that' -%>
    #
    #   # File: app/views/whatever/index.herb
    #
    #   <%= partial(:part1) %>
    #   <%= partial(:part2) %>
    #
    #   # Will generate the following in the final page...
    #   <html>
    #     <head>
    #       <script src="/javascripts/this.js" type="text/javascript"></script>
    #       <script src="/javascripts/something_else.js" type="text/javascript"></script>
    #       <link href="/stylesheets/that.css" media="all" rel="Stylesheet" type="text/css"/>
    #       <link href="/stylesheets/another_one.css" media="all" rel="Stylesheet" type="text/css"/>
    #     </head>
    #     .
    #     .
    #     .
    #   </html>
    #
    # See each method's documentation for more information.
    
    # The require_js method can be used to require any JavaScript
    # file anywhere in your templates. Regardless of how many times
    # a single script is included with require_js, Merb will only include
    # it once in the header.
    #
    # ==== Examples
    #   <% require_js 'jquery' %>
    #   # A subsequent call to include_required_js will render...
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #
    #   <% require_js 'jquery', 'effects' %>
    #   # A subsequent call to include_required_js will render...
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #   #    <script src="/javascripts/effects.js" type="text/javascript"></script>
    #
    def require_js(*js)
      @required_js ||= []
      @required_js |= js
    end
    
    # The require_ccs method can be used to require any CSS
    # file anywhere in your templates. Regardless of how many times
    # a single stylesheet is included with require_css, Merb will only include
    # it once in the header.
    #
    # ==== Examples
    #   <% require_css('style') %>
    #   # A subsequent call to include_required_css will render...
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    #   <% require_css('style', 'ie-specific') %>
    #   # A subsequent call to include_required_css will render...
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #   #    <link href="/stylesheets/ie-specific.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    def require_css(*css)
      @required_css ||= []
      @required_css |= css
    end
    
    # A method used in the layout of an application to create +<script>+ tags to include JavaScripts required in 
    # in templates and subtemplates using require_js.
    #
    # ==== Examples
    #   # my_action.herb has a call to require_js 'jquery'
    #   # File: layout/application.html.erb
    #   include_required_js
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #
    #   # my_action.herb has a call to require_js 'jquery', 'effects', 'validation'
    #   # File: layout/application.html.erb
    #   include_required_js
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #   #    <script src="/javascripts/effects.js" type="text/javascript"></script>
    #   #    <script src="/javascripts/validation.js" type="text/javascript"></script>
    #
    def include_required_js
      return '' if @required_js.nil?
      js_include_tag(*@required_js)
    end
    
    # A method used in the layout of an application to create +<link>+ tags for CSS stylesheets required in 
    # in templates and subtemplates using require_css.
    #
    # ==== Examples
    #   # my_action.herb has a call to require_css 'style'
    #   # File: layout/application.html.erb
    #   include_required_css
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    #   # my_action.herb has a call to require_js 'style', 'ie-specific'
    #   # File: layout/application.html.erb
    #   include_required_css
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #   #    <link href="/stylesheets/ie-specific.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    def include_required_css
      return '' if @required_css.nil?
      css_include_tag(*@required_css)
    end
    
    # The js_include_tag method will create a JavaScript 
    # +<include>+ tag for each script named in the arguments, appending
    # '.js' if it is left out of the call.
    #
    # ==== Examples
    #   js_include_tag 'jquery'
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #
    #   js_include_tag 'moofx.js', 'upload'
    #   # => <script src="/javascripts/moofx.js" type="text/javascript"></script>
    #   #    <script src="/javascripts/upload.js" type="text/javascript"></script>
    #
    #   js_include_tag :effects
    #   # => <script src="/javascripts/effects.js" type="text/javascript"></script>
    #
    #   js_include_tag :jquery, :validation
    #   # => <script src="/javascripts/jquery.js" type="text/javascript"></script>
    #   #    <script src="/javascripts/validation.js" type="text/javascript"></script>
    #
    def js_include_tag(*scripts)
      return nil if scripts.empty?
      include_tag = ""
      scripts.each do |script|
        script = script.to_s
        url = "/javascripts/#{script =~ /\.js$/ ? script : script + '.js'}"
        url = Merb::Server.config[:path_prefix] + url if Merb::Server.config[:path_prefix]
        include_tag << %Q|<script src="#{url}" type="text/javascript">//</script>\n|
      end
      include_tag
    end
    
    # The css_include_tag method will create a CSS stylesheet 
    # +<link>+ tag for each stylesheet named in the arguments, appending
    # '.css' if it is left out of the call.
    #
    # ==== Examples
    #   css_include_tag 'style'
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    #   css_include_tag 'style.css', 'layout'
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #   #    <link href="/stylesheets/layout.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    #   css_include_tag :menu
    #   # => <link href="/stylesheets/menu.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    #   css_include_tag :style, :screen
    #   # => <link href="/stylesheets/style.css" media="all" rel="Stylesheet" type="text/css"/>
    #   #    <link href="/stylesheets/screen.css" media="all" rel="Stylesheet" type="text/css"/>
    #
    def css_include_tag(*scripts)
      return nil if scripts.empty?
      include_tag = ""
      scripts.each do |script|
        script = script.to_s
        url = "/stylesheets/#{script =~ /\.css$/ ? script : script + '.css'}"
        url = Merb::Server.config[:path_prefix] + url if Merb::Server.config[:path_prefix]
        include_tag << %Q|<link href="#{url}" media="all" rel="Stylesheet" type="text/css"/>\n|
      end
      include_tag
    end
    
    # :section: Caching
    # ViewContextMixin provides views with fragment caching facilities.
    
    # The cache method is a simple helper method
    # for caching template fragments.  The value of the supplied
    # block is stored in the cache and identified by the string
    # in the +name+ argument.
    #
    # ==== Example
    #   <h1>Article list</h1>
    #
    #   <% cache(:article_list) do %>
    #     <ul>
    #     <% @articles.each do |a| %>
    #       <li><%= a.title %></li>
    #     <% end %>
    #     </ul>
    #   <% end %>
    #
    # See the documentation for Merb::Caching::Fragment for more
    # information.
    #
    def cache(name, &block)
      return block.call unless caching_enabled?
      buffer = eval("_buf", block.binding)
      if fragment = ::Merb::Caching::Fragment.get(name)
        buffer.concat(fragment)
      else
        pos = buffer.length
        block.call
        ::Merb::Caching::Fragment.put(name, buffer[pos..-1])
      end
    end
  
    # Calling throw_content stores the block of markup for later use.
    # Subsequently, you can make calls to it by name with <tt>catch_content</tt>
    # in another template or in the layout. 
    # 
    # Example:
    # 
    #   <% throw_content :header do %>
    #     alert('hello world')
    #   <% end %>
    #
    # You can use catch_content :header anywhere in your templates.
    #
    #   <%= catch_content :header %>
    #
    # You may find that you have trouble using thrown content inside a helper method
    # There are a couple of mechanisms to get around this.
    # 
    # 1. Pass the content in as a string instead of a block
    # 
    # Example: 
    #  
    #   throw_content(:header, "Hello World")
    #
    # In Haml Templates, use the 
    #
    #
    def throw_content(name, content = "", &block)
      content << capture(&block) if block_given?
      controller.thrown_content[name] << content
    end
    
    # Concat will concatenate text directly to the buffer of the template.
    # The binding must be supplied in order to obtian the buffer.  This can be called directly in the 
    # template as 
    # concat( "text", binding )
    #
    # or from a helper method that accepts a block as
    # concat( "text", block.binding )
    def concat( string, binding )
      _buffer( binding ) << string
    end
    
    # Creates the opening tag with attributes for the provided +name+
    # attrs is a hash where all members will be mapped to key="value"
    #
    # Note: This tag will need to be closed
    def open_tag(name, attrs = nil)
      "<#{name}#{(' ' + attrs.to_html_attributes) if attrs && !attrs.empty?}>"
    end
    
    # Creates a closing tag
    def close_tag(name)
      "</#{name}>"
    end
    
    # Creates a self closing tag.  Like <br/> or <img src="..."/>
    #
    # +name+ : the name of the tag to create
    # +attrs+ : a hash where all members will be mapped to key="value"
    def self_closing_tag(name, attrs = nil)
      "<#{name}#{' ' + attrs.to_html_attributes if attrs}/>"
    end    
  end  
end
