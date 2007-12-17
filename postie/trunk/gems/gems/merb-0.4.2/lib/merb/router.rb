module Merb

  class Router
    SEGMENT_REGEXP = /(:([a-z_][a-z0-9_]*|:))/
    SEGMENT_REGEXP_WITH_BRACKETS = /(:[a-z_]+)(\[(\d+)\])?/
    JUST_BRACKETS = /\[(\d+)\]/
    PARENTHETICAL_SEGMENT_STRING = "([^\/.,;?]+)".freeze

    @@named_routes = {}
    @@routes = []
    cattr_accessor :routes, :named_routes

    class << self
      def append(&block)
        prepare(@@routes, [], &block)
      end

      def prepend(&block)
        prepare([], @@routes, &block)
      end

      def prepare(first = [], last = [], &block)
        @@routes = []
        yield Behavior.new({}, {:action => 'index'}) # defaults
        @@routes = first + @@routes + last
        compile
      end

      def compiled_statement
        @@compiled_statement = "lambda { |request, params|\n"
        @@compiled_statement << "  cached_path = request.path\n  cached_method = request.method.to_s\n  "
        # @@compiled_statement << "  puts cached_path.inspect; puts cached_method.inspect\n"
        @@routes.each_with_index { |route, i| @@compiled_statement << route.compile(i == 0) }
        @@compiled_statement << "  else\n    [nil, {}]\n"
        @@compiled_statement << "  end\n"
        @@compiled_statement << "}"
      end

      def compile
        meta_def(:match, &eval(compiled_statement))
      end

      def generate(name, params = {}, fallback = {})
        raise "Named route not found: #{name}" unless @@named_routes.has_key? name
        @@named_routes[name].generate(params, fallback).sub(/\/$/, '').squeeze("/")
      end
    end # self

    # Cache procs for future reference in eval statement
    class CachedProc
      @@index = 0
      @@list = []

      attr_accessor :cache, :index

      def initialize(cache)
        @cache, @index = cache, CachedProc.register(self)
      end

      # Make each CachedProc object embeddable within a string
      def to_s() "CachedProc[#{@index}].cache" end

      class << self
        def register(cached_code)
          CachedProc[@@index] = cached_code
          @@index += 1
          @@index - 1
        end
        def []=(index, code) @@list[index] = code end
        def [](index) @@list[index] end
      end
    end # CachedProc

    class Route
      attr_reader :conditions, :conditional_block
      attr_reader :params, :behavior, :segments, :index, :symbol

      def initialize(conditions, params, behavior = nil, &conditional_block)
        @conditions, @params, @behavior = conditions, params, behavior
        @conditional_block = conditional_block
        if @behavior && (path = @behavior.merged_original_conditions[:path])
          @segments = segments_from_path(path)
        end
      end

      def to_s
        r = ""
        segments.each {|s|
          if s.is_a?(Symbol)
            r << ":#{s}"
          else
            r << s
          end
        }
        r
      end

      # Registers itself in the Router.routes array
      def register
        @index = Router.routes.size
        Router.routes << self
        self
      end

      # Get the symbols out of the segments array
      def symbol_segments
        segments.select{ |s| s.is_a?(Symbol) }
      end

      # Turn a path into string and symbol segments so it can be reconstructed, as in the
      # case of a named route.
      def segments_from_path(path)
        # Remove leading ^ and trailing $ from each segment (left-overs from regexp joining)
        strip = proc { |str| str.gsub(/^\^/, '').gsub(/\$$/, '') }
        segments = []
        while match = (path.match(SEGMENT_REGEXP))
          segments << strip[match.pre_match] unless match.pre_match.empty?
          segments << match[2].intern
          path = strip[match.post_match]
        end
        segments << strip[path] unless path.empty?
        segments
      end

      # Name this route
      def name(symbol = nil)
        @symbol = symbol
        Router.named_routes[@symbol] = self
      end

      def regexp?
        behavior.regexp? || behavior.send(:ancestors).any?{ |a| a.regexp? }
      end

      # Given a hash of +params+, returns a string using the stored route segments
      # for reconstruction of the URL.
      def generate(params = {}, fallback = {})
        url = @segments.map do |segment|
          value =
            if segment.is_a? Symbol
              if params.is_a? Hash
                params[segment] || fallback[segment]
              else
                if params.respond_to?(segment)
                  params.send(segment)
                else
                  fallback[segment]
                end
              end
            elsif segment.respond_to? :to_s
              segment
            else
              raise "Segment type '#{segment.class}' can't be converted to a string"
            end
          (value.respond_to?(:to_param) ? value.to_param : value).to_s
        end.join
      end

      def if_conditions(params_as_string)
        cond = []
        condition_string = proc do |key, value, regexp_string|
          max = Behavior.count_parens_up_to(value.source, value.source.size)
          captures = if max == 0 then "" else
            " && (" +
              (1..max).to_a.map{ |n| "#{key}#{n}" }.join(", ") + " = " +
              (1..max).to_a.map{ |n| "$#{n}"}.join(", ") +
            ")"
          end
          "    (#{value.inspect} =~ #{regexp_string}" + captures + ")"
        end
        @conditions.each_pair do |key, value|

          # Note: =~ is slightly faster than .match
          cond << case key
          when :path then condition_string[key, value, "cached_path"]
          when :method then condition_string[key, value, "cached_method"]
          else condition_string[key, value, "request.#{key}.to_s"]
          end
        end
        if @conditional_block
          str = "  # #{@conditional_block.inspect.scan(/@([^>]+)/).flatten.first}\n"
          str << "    (block_result = #{CachedProc.new(@conditional_block)}.call(request, params.merge({#{params_as_string}})))" if @conditional_block
          cond << str
        end
        cond
      end

      def compile(first = false)
        code = ""
        default_params = {:action => "index"}
        get_value = proc do |key|
          if default_params.has_key?(key) && params[key][0] != ?"
            "#{params[key]} || \"#{default_params[key]}\""
          else
            "#{params[key]}"
          end
        end
        params_as_string = params.keys.map{|k| "#{k.inspect} => #{get_value[k]}"}.join(", ")
        code << "  els" unless first
        code << "if  # #{@behavior.merged_original_conditions.inspect}\n  "
        code << if_conditions(params_as_string).join(" &&\n  ") << "\n"
        code << "    # then\n"
        if @conditional_block
          code << "    [#{@index.inspect}, block_result]\n"
        else
          code << "    [#{@index.inspect}, {#{params_as_string}}]\n"
        end
      end

      def behavior_trace
        if @behavior
          puts @behavior.send(:ancestors).reverse.map{|a| a.inspect}.join("\n"); puts @behavior.inspect; puts
        else
          puts "No behavior to trace #{self}"
        end
      end
    end # Route

    # The Behavior class is an interim route-building class that ties pattern-matching +conditions+ to
    # output parameters, +params+.
    class Behavior
      attr_reader :placeholders, :conditions, :params
      attr_accessor :parent

      def initialize(conditions = {}, params = {}, parent = nil)
        @conditions, @params, @parent = conditions, {}, parent
        @placeholders = {}
        stringify_conditions
        copy_original_conditions
        deduce_placeholders
        # Must wait until after deducing placeholders to set @params
        @params.merge!(params)
      end

      def add(path, params = {})
        match(path).to(params)
      end

      # Matches a +path+ and any number of optional request methods as conditions of a route.
      # Alternatively, +path+ can be a hash of conditions, in which case +conditions+ is ignored.
      # Yields 'self' so that sub-matching may occur.
      def match(path = '', conditions = {}, &block)
        if path.is_a? Hash
          conditions = path
        else
          conditions[:path] = path
        end
        match_without_path(conditions, &block)
      end

      def match_without_path(conditions = {})
        new_behavior = self.class.new(conditions, {}, self)
        conditions.delete :path if ['', '^$'].include?(conditions[:path])
        yield new_behavior if block_given?
        new_behavior
      end

      def to_route(params = {}, &conditional_block)
        @params.merge!(params)
        Route.new(compiled_conditions, compiled_params, self, &conditional_block)
      end

      # Creates a Route from one or more Behavior objects, unless a +block+ is passed in.
      # If a block is passed in, a Behavior object is yielded and further .to operations
      # may be called in the block.  For example:
      #   r.match('/:controller/:id).to(:action => 'show')
      # vs.
      #   r.to(:controller => "simple") do |simple|
      #     simple.match('/test').to(:action => 'index')
      #     simple.match('/other').to(:action => 'other')
      #   end
      def to(params = {}, &block)
        if block_given?
          new_behavior = self.class.new({}, params, self)
          yield new_behavior if block_given?
          new_behavior
        else
          to_route(params).register
        end
      end

      # Takes a block and stores it for defered conditional routes.  The block takes the
      # +request+ object and the +params+ hash as parameters and should return a hash of params.
      # For example:
      #   r.defer_to do |request, params|
      #     params.merge(:controller => 'here', :action => 'there') if External.says_so?
      #   end
      def defer_to(params = {}, &conditional_block)
        Router.routes << (route = to_route(params, &conditional_block))
        route
      end

      def default_routes(params = {}, &block)
        match(%r[/:controller(/:action(/:id)?)?(\.:format)?]).to(params, &block)
      end

      def to_resources(params = {}, &block)
        many_behaviors_to(resources_behaviors, params, &block)
      end

      def resources(name, options = {})
        # singular = name.singularize
        next_level = match("/#{name}")
        behaviors = []

        singular = name.to_s.singularize
        
        namespace = options[:namespace] || merged_params[:namespace]
        
        if options[:name_prefix].nil? && namespace != nil
          options[:name_prefix] = "#{namespace}_"
        end
        
        name_prefix = options.delete(:name_prefix)


        route_plural_name = "#{name_prefix}#{name}"
        route_singular_name = "#{name_prefix}#{singular}"

        member = options.delete(:member)
        collection = options.delete(:collection)

        # Add optional member actions

        member.each_pair do |action, methods|
          conditions = {:path => %r[^/:id[/;]#{action}$], :method => /^(#{[methods].flatten.join("|")})$/}
          behaviors << Behavior.new(conditions, {:action => action.to_s}, next_level)
          next_level.match("/:id/#{action}").
            to_route.name(:"#{action}_#{route_singular_name}")
        end if member

        # Add optional collection actions
        collection.each_pair do |action, methods|
          conditions = {:path => %r[^[/;]#{action}$], :method => /^(#{[methods].flatten.join("|")})$/}
          behaviors << Behavior.new(conditions, {:action => action.to_s}, next_level)
          next_level.match("/#{action}").to_route.name(:"#{action}_#{route_plural_name}")
        end if collection

        options[:controller] ||= merged_params[:controller] || name.to_s
        routes = many_behaviors_to(behaviors + next_level.send(:resources_behaviors), options)

        # Add names to some routes
        next_level.match("").to_route.name(:"#{route_plural_name}")
        next_level.match("/:id").to_route.name(:"#{route_singular_name}")
        next_level.match("/new").to_route.name(:"new_#{route_singular_name}")
        next_level.match("/:id/edit").to_route.name(:"edit_#{route_singular_name}")
        next_level.match("/:action/:id").to_route.name(:"custom_#{route_singular_name}")

        yield next_level.match("/:#{singular}_id") if block_given?
        routes
      end

      def to_resource(params = {}, &block)
        many_behaviors_to(resource_behaviors, params, &block)
      end

      def resource(name, options = {})
        next_level = match("/#{name}")

        options[:controller] ||= merged_params[:controller] || name.to_s
        name_prefix = options.delete(:name_prefix)
        routes = next_level.to_resource(options)

        namespace = options[:namespace] || merged_params[:namespace] 
        
        if options[:name_prefix].nil? && namespace != nil
          options[:name_prefix] = "#{namespace}_"
        end
        
        route_name = "#{name_prefix}#{name}"

        next_level.match("").to_route.name(:"#{route_name}")
        next_level.match("/new").to_route.name(:"new_#{route_name}")
        next_level.match("/edit").to_route.name(:"edit_#{route_name}")

        yield next_level if block_given?
        routes
      end

      def merged_original_conditions
        if parent.nil?
          @original_conditions
        else
          merged_so_far = parent.merged_original_conditions
          path = Behavior.concat_without_endcaps(merged_so_far[:path], @original_conditions[:path])
          path ?
            merged_so_far.merge(@original_conditions).merge(:path => path) :
            merged_so_far.merge(@original_conditions)
        end
      end

      def merged_conditions
        if parent.nil?
          @conditions
        else
          merged_so_far = parent.merged_conditions
          path = Behavior.concat_without_endcaps(merged_so_far[:path], @conditions[:path])
          path ?
            merged_so_far.merge(@conditions).merge(:path => path) :
            merged_so_far.merge(@conditions)
        end
      end

      def merged_params
        if parent.nil?
          @params
        else
          parent.merged_params.merge(@params)
        end
      end

      def merged_placeholders
        placeholders = {}
        (ancestors.reverse + [self]).each do |a|
          a.placeholders.each_pair do |key, pair|
            param, place = pair
            placeholders[key] = [param, place + (param == :path ? a.total_previous_captures : 0)]
          end
        end
        placeholders
      end

      def inspect
        "[captures: #{path_captures}, conditions: #{@original_conditions.inspect}, params: #{@params.inspect}, placeholders: #{@placeholders.inspect}]"
      end

      def regexp?
        @conditions_have_regexp
      end

    protected
      def resources_behaviors(parent = self)
        [
          Behavior.new({:path => %r[^/?(\.:format)?$],     :method => :get},    {:action => "index"},   parent),
          Behavior.new({:path => %r[^/index(\.:format)?$], :method => :get},    {:action => "index"},   parent),
          Behavior.new({:path => %r[^/new$],               :method => :get},    {:action => "new"},     parent),
          Behavior.new({:path => %r[^/?(\.:format)?$],     :method => :post},   {:action => "create"},  parent),
          Behavior.new({:path => %r[^/:id(\.:format)?$],   :method => :get},    {:action => "show"},    parent),
          Behavior.new({:path => %r[^/:id[;/]edit$],       :method => :get},    {:action => "edit"},    parent),
          Behavior.new({:path => %r[^/:id(\.:format)?$],   :method => :put},    {:action => "update"},  parent),
          Behavior.new({:path => %r[^/:id(\.:format)?$],   :method => :delete}, {:action => "destroy"}, parent)
        ]
      end

      def resource_behaviors(parent = self)
        [
          Behavior.new({:path => %r{^[;/]new$},        :method => :get},    {:action => "new"},       parent),
          Behavior.new({:path => %r{^/?(\.:format)?$}, :method => :post},   {:action => "create"},    parent),
          Behavior.new({:path => %r{^/?(\.:format)?$}, :method => :get},    {:action => "show"},      parent),
          Behavior.new({:path => %r{^[;/]edit$},       :method => :get},    {:action => "edit"},      parent),
          Behavior.new({:path => %r{^/?(\.:format)?$}, :method => :put},    {:action => "update"},    parent),
          Behavior.new({:path => %r{^/?(\.:format)?$}, :method => :delete}, {:action => "destroy"},   parent)
        ]
      end

      # Creates a series of routes from an array of Behavior objects.
      # You can pass in optional +params+, and an optional block that will be
      # passed along to the #to method.
      def many_behaviors_to(behaviors, params = {}, &conditional_block)
        routes = []
        behaviors.each { |b| routes << b.to(params, &conditional_block) }
        routes
      end

      # Convert conditions to regular expression string sources for consistency
      def stringify_conditions
        @conditions_have_regexp = false
        @conditions.each_pair do |key, value|
          # TODO: Other Regexp special chars
          @conditions[key] = case value
            when String then "^" + value.escape_regexp + "$"
            when Symbol then "^" + value.to_s + "$"
            when Regexp:
              @conditions_have_regexp = true
              value.source
            end
        end
      end

      def copy_original_conditions
        @original_conditions = {}
        @conditions.each_pair do |key, value|
          @original_conditions[key] = value.dup
        end
        @original_conditions
      end

      def deduce_placeholders
        @conditions.each_pair do |match_key, source|
          while match = SEGMENT_REGEXP.match(source)
            source.sub!(SEGMENT_REGEXP, PARENTHETICAL_SEGMENT_STRING)
            unless match[2] == ":" # No need to store anonymous place holders
              placeholder_key = match[2].intern
              @params[placeholder_key] = "#{match[1]}"
              @placeholders[placeholder_key] = [match_key, Behavior.count_parens_up_to(source, match.offset(1)[0])]
            end
          end
        end
      end

      def ancestors(list = [])
        if parent.nil?
          list
        else
          list.push parent
          parent.ancestors(list)
          list
        end
      end

      # Count the number of regexp captures in the :path condition
      def path_captures
        return 0 unless conditions[:path]
        Behavior.count_parens_up_to(conditions[:path], conditions[:path].size)
      end

      def total_previous_captures
        ancestors.map{|a| a.path_captures}.inject(0){|sum, n| sum + n}
      end

      # def merge_with_ancestors
      #   self.class.new(merged_conditions, merged_params)
      # end

      def compiled_conditions(conditions = merged_conditions)
        compiled = {}
        conditions.each { |key, value| compiled[key] = Regexp.new(value) }
        compiled
      end

      # Compiles the params hash into 'eval'-able form.
      # For example:
      #   @params = {:controller => "admin/:controller"}
      # Could become:
      #   {:controller => "'admin/' + matches[:path][1]"}
      #
      def compiled_params(params = merged_params, placeholders = merged_placeholders)
        compiled = {}
        params.each_pair do |key, value|
          raise ArgumentError, "param value must be string (#{value.inspect})" unless value.is_a? String
          result = []
          value = value.dup
          match = true
          while match
            if match = SEGMENT_REGEXP_WITH_BRACKETS.match(value)
              result << match.pre_match unless match.pre_match.empty?
              ph_key = match[1][1..-1].intern
              if match[2] # has brackets, e.g. :path[2]
                result << :"#{ph_key}#{match[3]}"
              else # no brackets, e.g. a named placeholder such as :controller
                if place = placeholders[ph_key]
                  result << :"#{place[0]}#{place[1]}"
                else
                  raise "Placeholder not found while compiling routes: :#{ph_key}"
                end
              end
              value = match.post_match
            elsif match = JUST_BRACKETS.match(value)
              # This is a reference to :path
              result << match.pre_match unless match.pre_match.empty?
              result << :"path#{match[1]}"
              value = match.post_match
            else
              result << value unless value.empty?
            end
          end
          compiled[key] = Behavior.array_to_code(result).gsub("\\_", "_")
        end
        compiled
      end

    public
      # Count the number of open parentheses in +string+, up to and including +pos+
      def self.count_parens_up_to(string, pos)
        string[0..pos].gsub(/[^\(]/, "").size
      end

      # Concatenate strings and remove regexp end caps
      def self.concat_without_endcaps(string1, string2)
        return nil if !string1 and !string2
        return string1 if string2.nil?
        return string2 if string1.nil?
        s1 = string1[-1] == ?$ ? string1[0..-2] : string1
        s2 = string2[0] == ?^ ? string2[1..-1] : string2
        s1 + s2
      end

      # Join an array's elements into a string using " + " as a joiner, and
      # surround string elements in quotes.
      def self.array_to_code(arr)
        code = ""
        arr.each_with_index do |part, i|
          code << " + " if i > 0
          case part
          when Symbol
            code << "#{part}"
          when String
            code << "\"" + part + "\""
          else
            raise "Don't know how to compile array part: #{part.class} [#{i}]"
          end
        end
        code
      end
    end # Behavior

  end
end
