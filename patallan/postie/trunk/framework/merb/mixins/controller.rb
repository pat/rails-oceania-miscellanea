module Merb
  # Module that is mixed in to all implemented controllers.
  module ControllerMixin
    
    # Returns a URL according to the defined route.  Accepts the path and
    # an options hash.  The path specifies the route requested.  The options 
    # hash fills in the dynamic parts of the route.
    #
    # Merb routes can often be one-way; if they use a regex to define
    # the route, then knowing the controller & action won't be enough
    # to reverse-generate the route.  However, if you use the default
    # /controller/action/id?query route, +default_route+ can generate
    # it for you.
    #
    # For easy reverse-routes that use a Regex, be sure to also add
    # a name to the route, so +url+ can find it.
    # 
    # Nested resources such as:
    #
    #  r.resources :blogposts do |post|
    #    post.resources :comments
    #  end
    #
    # Provide the following routes:
    #
    #   [:blogposts, "/blogposts"]
    #   [:blogpost, "/blogposts/:id"]
    #   [:edit_blogpost, "/blogposts/:id/edit"]
    #   [:new_blogpost, "/blogposts/new"]
    #   [:custom_new_blogpost, "/blogposts/new/:action"]
    #   [:comments, "/blogposts/:blogpost_id/comments"]
    #   [:comment, "/blogposts/:blogpost_id/comments/:id"]
    #   [:edit_comment, "/blogposts/:blogpost_id/comments/:id/edit"]
    #   [:new_comment, "/blogposts/:blogpost_id/comments/new"]
    #   [:custom_new_comment, "/blogposts/:blogpost_id/comments/new/:action"]
    #
    #
    # ==== Parameters
    #
    # :route_name: - Symbol that represents a named route that you want to use, such as +:edit_post+.
    # :new_params: - Parameters to be passed to the generated URL, such as the +id+ for a record to edit.
    #
    # ==== Examples
    #
    #  @post = Post.find(1)
    #  @comment = @post.comments.find(1)
    #
    #  url(:blogposts)                                    # => /blogposts
    #  url(:new_post)                                     # => /blogposts/new
    #  url(:blogpost, @post)                              # => /blogposts/1
    #  url(:edit_blogpost, @post)                         # => /blogposts/1/edit
    #  url(:custom_new_blogpost, :action => 'alternate')  # => /blogposts/new/alternate
    #   
    #  url(:comments, :blogpost => @post)         # => /blogposts/1/comments
    #  url(:new_comment, :blogpost => @post)      # => /blogposts/1/comments/new
    #  url(:comment, @comment)                    # => /blogposts/1/comments/1
    #  url(:edit_comment, @comment)               # => /blogposts/1/comments/1/edit
    #  url(:custom_new_comment, :blogpost => @post)
    #
    #  url(:page => 2)                            # => /posts/show/1?page=2
    #  url(:new_post, :page => 3)                 # => /posts/new?page=3
    #  url('/go/here', :page => 3)                # => /go/here?page=3
    #
    #  url(:controller => "welcome")              # => /welcome
    #  url(:controller => "welcome", :action => "greet")
    #                                             # => /welcome/greet
    #
    def url(route_name = nil, new_params = {})
      if route_name.is_a?(Hash)
        new_params = route_name
        route_name = nil
      end
      
      url = if new_params.respond_to?(:keys) && route_name.nil? &&
        !(new_params.keys & [:controller, :action, :id]).empty?
          url_from_default_route(new_params)
        elsif route_name.nil? && !route.regexp?
          url_from_route(route, new_params)
        elsif route_name.nil?
          request.path + (new_params.empty? ? "" : "?" + params_to_query_string(new_params))
        elsif route_name.is_a?(Symbol)
          url_from_route(route_name, new_params)
        elsif route_name.is_a?(String)
          route_name + (new_params.empty? ? "" : "?" + params_to_query_string(new_params))
        else
          raise "URL not generated: #{route_name.inspect}, #{new_params.inspect}"
        end
      url = MerbHandler.path_prefix + url if MerbHandler.path_prefix
      url
    end

    def url_from_route(symbol, new_params = {})
      if new_params.respond_to?(:new_record?) && new_params.new_record?
        symbol = "#{symbol}".singularize.to_sym
        new_params = {}
      end
      route = symbol.is_a?(Symbol) ? Merb::Router.named_routes[symbol] : symbol
      raise "URL could not be constructed. Route symbol not found: #{symbol.inspect}" unless route
      path = route.generate(new_params, params)
      keys = route.symbol_segments
      if new_params.is_a? Hash
        if ext = format_extension(new_params)
          new_params.delete(:format)
          path += "." + ext
        end
        extras = new_params.reject{ |k, v| keys.include?(k) }
        path += "?" + params_to_query_string(extras) unless extras.empty?
      end
      path
    end
    
    # this is pretty ugly, but it works.  TODO: make this cleaner
    def url_from_default_route(new_params)
      query_params = new_params.reject do |k,v|
        [:controller, :action, :id, :format].include?(k)
      end
      controller = new_params[:controller] || params[:controller]
      controller = params[:controller] if controller == :current
      url = "/#{controller}"
      if new_params[:action] || new_params[:id] ||
                new_params[:format] || !query_params.empty?
        action = new_params[:action] || params[:action]
        url += "/#{action}"
      end
      if new_params[:id]
        url += "/#{new_params[:id]}"
      end
      if format = new_params[:format]
        format = params[:format] if format == :current
        url += ".#{format}"
      end
      unless query_params.empty?
        url += "?" + params_to_query_string(query_params)
      end
      url
    end

    protected

    # Creates query string from params, supporting nested arrays and hashes.
    # ==== Example
    #   params_to_query_string(:user => {:filter => {:name => "quux*"}, :order => ["name"]})
    #   # => user[filter][name]=quux%2A&user[order][]=name
    def params_to_query_string(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          params_to_query_string(v, "#{prefix}[]")
        } * "&"
      when Hash
        value.map { |k, v|
          params_to_query_string(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        } * "&"
      else
        "#{prefix}=#{escape(value)}"
      end
    end
    
    # +format_extension+ dictates when named route URLs generated by the url
    # method will have a file extension. It will return either false or the format 
    # extension to append.
    #
    # ==== Configuration Options
    #
    # By default, non-HTML URLs will be given an extension. It is posible 
    # to override this behaviour by setting +:use_format_in_urls+ in your 
    # Merb config (merb.yml) to either true/false.
    #
    # +true+  Results in all URLs (even HTML) being given extensions.
    #         This effect is often desirable when you have many formats and dont
    #         wish to treat .html any differently than any other format. 
    # +false+ Results in no URLs being given extensions and +format+
    #         gets treated just like any other param (default).
    #
    # ==== Method parameters
    # 
    # +new_params+ - New parameters to be appended to the URL
    #
    # ==== Examples
    #
    #   url(:post, :id => post, :format => 'xml')
    #   # => /posts/34.xml
    #
    #   url(:accounts, :format => 'yml')
    #   # => /accounts.yml
    #
    #   url(:edit_product, :id => 3, :format => 'html')
    #   # => /products/3
    #
    def format_extension(new_params={})
      use_format = Merb::Server.config[:use_format_in_urls]
      if use_format.nil?
        prms = params.merge(new_params)
        use_format = prms[:format] != 'html' && prms[:format]
      end
      use_format
    end
    
    # Renders the block given as a parameter using chunked
    # encoding.
    #
    # ==== Examples
    #
    #   def stream
    #     prefix = '<p>'
    #     suffix = "</p>\r\n"
    #     render_chunked do
    #       IO.popen("cat /tmp/test.log") do |io|
    #         done = false
    #         until done
    #           sleep 0.3
    #           line = io.gets.chomp
    #           
    #           if line == 'EOF'
    #             done = true
    #           else
    #             send_chunk(prefix + line + suffix)
    #           end
    #         end
    #       end
    #     end
    #   end
    #
    def render_chunked(&blk)
      headers['Transfer-Encoding'] = 'chunked'
      Proc.new {
        response.send_status_no_connection_close(0)
        response.send_header
        blk.call
        response.write("0\r\n\r\n")
      }
    end
    
    # Returns a +Proc+ that Mongrel can call later, allowing
    # Merb to release the thread lock and render another request.
    #
    def render_deferred(&blk)
      Proc.new {
        result = blk.call
        response.send_status(result.length)
        response.send_header
        response.write(result)
      }
    end
    
    # Writes a chunk from render_chunked to the response that
    # is sent back to the client.
    def send_chunk(data)
      response.write('%x' % data.size + "\r\n")
      response.write(data + "\r\n")
    end
    
    # Redirects to a URL.  The +url+ parameter can be either 
    # a relative URL (e.g., +/posts/34+) or a fully-qualified URL
    # (e.g., +http://www.merbivore.com/+).
    #
    # ==== Parameters
    #
    # +url+ - URL to redirect to; it can be either a relative or 
    # fully-qualified URL.
    #
    def redirect(url)
      MERB_LOGGER.info("Redirecting to: #{url}")
      set_status(302)
      headers['Location'] = url
      "<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>"
    end
    
    # Sends a file over HTTP.  When given a path to a file, it will set the
    # right headers so that the static file is served directly.
    #
    # ==== Parameters
    # 
    # +file+ - Path to file to send to the client.
    #
    def send_file(file, opts={})
      opts.update(Merb::Const::DEFAULT_SEND_FILE_OPTIONS.merge(opts))
      disposition = opts[:disposition].dup || 'attachment'
      disposition << %(; filename="#{opts[:filename] ? opts[:filename] : File.basename(file)}")
      headers.update(
        'Content-Type'              => opts[:type].strip,  # fixes a problem with extra '\r' with some browsers
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary',
        'X-SENDFILE'                => file
      )
      return
    end
    
    # Streams a file over HTTP.
    #
    # ==== Example
    #
    # stream_file( { :filename => file_name, 
    #                :type => content_type,
    #                :content_length => content_length }) do
    #   AWS::S3::S3Object.stream(user.folder_name + "-" + user_file.unique_id, bucket_name) do |chunk|
    #       response.write chunk
    #   end
    # end
    def stream_file(opts={}, &stream)
      opts.update(Merb::Const::DEFAULT_SEND_FILE_OPTIONS.merge(opts))
      disposition = opts[:disposition].dup || 'attachment'
      disposition << %(; filename="#{opts[:filename]}")
      response.headers.update(
        'Content-Type'              => opts[:type].strip,  # fixes a problem with extra '\r' with some browsers
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary',
        'CONTENT-LENGTH'            => opts[:content_length]
      )
      response.send_status(opts[:content_length])
      response.send_header
      stream
    end
    

    # Uses the nginx specific +X-Accel-Redirect+ header to send
    # a file directly from nginx. For more information, see the nginx wiki:
    # http://wiki.codemongers.com/NginxXSendfile
    #
    # ==== Parameters
    # 
    # +file+ - Path to file to send to the client.
    #
    def nginx_send_file(file)
      headers['X-Accel-Redirect'] = File.expand_path(file)
      return
    end  
  
    # Sets a cookie to be included in the response.  This method is used
    # primarily internally in Merb.
    #
    # If you need to set a cookie, then use the +cookies+ hash.
    #
    def set_cookie(name, value, expires)
      (headers['Set-Cookie'] ||='') << (Merb::Const::SET_COOKIE % [
        name.to_s, 
        escape(value.to_s), 
        # Cookie expiration time must be GMT. See RFC 2109
        expires.gmtime.strftime(Merb::Const::COOKIE_EXPIRATION_FORMAT)
      ])
    end
    
    # Marks a cookie as deleted and gives it an expires stamp in 
    # the past.  This method is used primarily internally in Merb.
    #
    # Use the +cookies+ hash to manipulate cookies instead.
    #
    def delete_cookie(name)
      set_cookie(name, nil, Merb::Const::COOKIE_EXPIRED_TIME)
    end
  
    # Creates an MD5 hashed token based on the current time.
    #
    # ==== Example
    #   make_token
    #   # => "b9a82e011694cc13a4249731b9e83cea" 
    #
    def make_token
      require 'digest/md5'
      Digest::MD5.hexdigest("#{inspect}#{Time.now}#{rand}")
    end

    # Escapes the string representation of +obj+ and escapes
    # it for use in XML.
    #
    # ==== Parameter
    #
    # +obj+ - The object to escape for use in XML.
    #
    def escape_xml(obj)
      obj.to_s.gsub(/[&<>"']/) { |s| Merb::Const::ESCAPE_TABLE[s] }
    end
    alias h escape_xml
    alias html_escape escape_xml
  
    # Escapes +s+ for use in a URL.
    #
    # ==== Parameter
    #
    # +s+ - String to URL escape.
    #
    def escape(s)
      Mongrel::HttpRequest.escape(s)
    end
  
    # Unescapes a string (i.e., reverse URL escaping).
    #
    # ==== Parameter 
    #
    # +s+ - String to unescape.
    #
    def unescape(s)
      Mongrel::HttpRequest.unescape(s)
    end
  
  end
end
