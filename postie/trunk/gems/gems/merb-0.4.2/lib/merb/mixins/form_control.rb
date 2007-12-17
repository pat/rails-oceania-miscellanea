require 'date'
require 'ostruct'

class OpenStruct
  def temp(hash)
    OpenStruct.new(@table.merge(hash))
  end
end

module Merb
  module FormControls
    #
    # This is the main merb form control helper. 
    # The types that can be rendered are
    #   
    #   text     => A standard textfield
    #   textarea => A textarea
    #   password => A password field
    #   date     => A select menu with day, month and year
    #   time     => As date + hour, minute and second
    #   select   => A select menu for a custom collection in Array or Hash
    #
    #
    # HTML-formatting and some control-options can be given in +options+
    #
    # === Defaults
    #   id    => obj.class       (class_name_in_camel_case)
    #   name  => obj.class[meth] (class_name_in_camel_case[control_method])
    #   value => The value of obj.meth 
    #
    # ==== Options
    # +HTML+, +DOM+ and +CSS+
    #   :class, :size, :rows, :cols, :name, ...
    #
    # +label+
    # Setting this label will include a label tag pointing at the field that 
    # displays the value of :label in the options hash
    #
    #
    # ==== Examples
    # The bare minimum
    #   <%= control_for @post, :title, :text%>
    # renders a textfield for @post.title
    #
    #   <%= control_for @post, :content, :textarea %>
    # renders a textarea for @post.content
    #
    #   <%= control_for @post, :secret, :password %>
    # renders a password-field for @post.secret
    #     
    # Some HTML and CSS options
    #   <%= control_for @post, :title, :text, 
    #       :id => 'foo', :size => 53 %>
    #
    #   <%= control_for @post, :content, :textarea, 
    #       :class => 'post_intro', :rows => 10, :cols => 50 %>
    #
    #
    # === Time and date
    #
    # +monthnames+
    # for time and date selects, shows monthnames as text. 
    # An array of monthnames can be supplied
    #   (defaults to Date::MONTHNAMES)
    # 
    # +min_year+ and +max_year+
    # for time and date selects, sets the first and last year
    #   (defaults to 1950 and 2050)
    #
    # ==== Examples
    #
    # Simple time and date
    #   <%= control_for @post, :created_at, :time %>
    #   <%= control_for @post, :published_at, :date %>
    #
    # In time and date controls, monthnames can be added
    #   <%= control_for @post, :created_at, :time, :monthnames => true %>
    #
    # You can also specify other month-names                      
    #   <%= control_for @post, :published_at, :date, 
    #                       :monthnames => Date::ABBR_MONTHNAMES %>
    # or 
    #   french_months = [nil] + %w(janvier février mars avril mai juin 
    #                   juillet août septembre octobre novembre décembre)
    #   
    #   <%= control_for @post, :published_at, :date, 
    #                         {:monthnames => french_months} %> 
    #                       
    # In time and date controls, :min_year and :max_year can be specified. 
    # Defaults to 1950..2050
    #   <%= control_for @post, :created_at, :time, 
    #       :min_year => 2000, :max_year => 2010 %>
    #   
    #   <%= control_for @post, :published_at, :date, 
    #       :min_year => Date.today.year, :max_year => Date.today.year+2 %>
    # 
    # 
    # === Select Tags
    # The control_for( object, :method, :select, {:collection => collection} )
    # creates a <select> tag that automatically selects the given object
    #
    # === Special Options
    # +collection+
    # The collection can be an array of objects, or a hash of arrays of objects.  
    # This is required if you want any options to be displayed
    # 
    # +text_method+
    # The method that will provide the text for the option to display to the user.  
    # By default it will use the control method
    # 
    # +include_blank+
    # Includes a blank option at the top of the list if set to true
    # 
    # All options provided to the call to control_for are rendered as xml/html tag attributes
    #
    # ==== Examples
    #
    # Imagine cars, with a brand (BMW, Toyota, ...) a model
    # (Z3, Carina, Prius) and some internal code.
    #
    #   class Car 
    #     ...
    #     attr_reader :brand, :model, :code
    #   end
    #
    # An array of objects 
    #   @all_cars = [ car1, car2, car3 ]
    # 
    #   <%= control_for @car2, :code, :select, 
    #                {:text_method => :model, :collection => @all_cars } %>
    #
    #   <select name="car[code]" id="car_code">
    #     <option                     value="code_for_car_1">Z3</option>
    #     <option selected="selected" value="code_for_car_2">Carina</option>
    #     <option                     value="code_for_car_3">Prius</option>
    #   </select>
    #
    # The same array of cars but run through a group_by on :brand to give a hash
    #  
    #   @all_cars = @all_cars.group_by{|car| car.brand }
    #  
    #   { :bmw    => [car1],
    #     :toyota => [car2, car3] 
    #   }
    # 
    #   <%= control_for @car2, :code, :select, 
    #                {:text_method => :model, :collection => @all_cars } %>
    #
    #   <select name="car[code]" id="car_code">
    #     <optgroup label="BMW">
    #       <option value="code_for_car_1">Z3</option>
    #     </optgroup>
    #     <optgroup label="Toyota">
    #       <option selected="selected" value="code_for_car_2">Carina</option>
    #       <option                     value="code_for_car_3">Prius</option>
    #     </optgroup>
    #  </select>
    #
    
    def control_for( obj, meth, type, opts = {} )
      instance = obj
      obj = obj.class
      # FooBar        => foo_bar
      # Admin::FooBar => admin_foo_bar
      obj_dom_id = Inflector.underscore(obj.to_s).gsub('/', '_')
      default_opts = {
        # These are in here to make sure that they are set.  They can be overridden if the user wants to.
        :id   => "#{obj_dom_id}_#{meth}",
        :name => "#{obj_dom_id}[#{meth}]",
        :value => (instance.send(meth) rescue nil) || ""
      }
      o = OpenStruct.new(
                         :value => default_opts[:value], # Just for convenience
                         :label => ( opts.has_key?( :label ) ? opts.delete( :label ) : nil ),
                         :monthnames => (if opts.has_key?(:monthnames)
                                           opts[:monthnames]==true ? Date::MONTHNAMES : opts.delete(:monthnames)
                                         else
                                           nil 
                                         end), 
                         :meth  => meth,
                         :obj   => instance,
                         :min_year => (opts.has_key?(:min_year) ? opts.delete(:min_year) : 1950),
                         :max_year => (opts.has_key?(:max_year) ? opts.delete(:max_year) : 2050),
                         :html  => default_opts.merge(opts))
      Control.send(type, o)
    end
    
    module Control
      
      # This was ripped wholesale from Ramaze and has had some fairly major modifications to work
      # with AR objects instead of Og. Thanks again to Michael Fellinger.
      class << self

        def number(o)
          o.value = o.html[:value] = 0 if o.value == ""
          text(o)
        end

        def hidden(o)
          input_tag( o.html.merge( :type => 'hidden' ) )
        end
        
        def text(o)
          tag = ''
          tag << label_for_object( o )
          tag << input_tag( o.html.merge( :type => 'text' ) )
        end
        
       def password(o)
         o.html.delete( :value ) if o.html.has_key?( :value ) # The password field should not be filled in
         tag = ''
         tag << label_for_object( o )
         tag << input_tag( o.html.merge( :type => 'password' ) )
       end

        def textarea(o)
          tag = ''
          tag << label_for_object( o )
          tag << %{<textarea #{o.html.to_xml_attributes }>#{o.value}</textarea>}
        end

        def date(o)
          o.value = Date.today unless (o.value.is_a? Time or o.value.is_a? Date or o.value.is_a? DateTime)
          selects = []
          selects << label_for_object( o )
          selects << date_day(o.temp(:value   => o.value.day))
          selects << date_month(o.temp(:value => o.value.month))
          selects << date_year(o.temp(:value  => o.value.year))
          selects.join("\n")
        end

        def time(o)
          o.value = Time.now unless (o.value.is_a? Time or o.value.is_a? DateTime)
          selects = []
          selects << label_for_object( o )
          selects << date_day(o.temp(:value    => o.value.day))
          selects << date_month(o.temp(:value  => o.value.month))
          selects << date_year(o.temp(:value   => o.value.year))
          selects << time_hour(o.temp(:value   => o.value.hour))
          selects << time_minute(o.temp(:value => o.value.min))
          selects << time_second(o.temp(:value => o.value.sec))
          selects.join("\n")
        end

        def time_second(o) select_tag(o.html[:name] +'[second]', (0...60),o.value) end
        def time_minute(o) select_tag(o.html[:name] +'[minute]', (0...60),o.value) end
        def time_hour(o)   select_tag(o.html[:name] +'[hour]',   (0...24),o.value) end
        def date_day(o)    select_tag(o.html[:name] +'[day]',    (1..31),o.value)  end
        def date_month(o)  select_tag(o.html[:name] +'[month]',  (1..12),o.value, ( o.monthnames.compact unless o.monthnames.nil? )) end
        def date_year(o)   select_tag(o.html[:name] +'[year]',   (o.min_year..o.max_year),o.value) end
        
        def select( o )
          options = {}
            [:collection, :text_method, :include_blank].each do |value|
            options[value] = o.html.has_key?( value ) ? o.html.delete( value ) : nil
          end
          out = ""
          out << label_for_object( o )
          out << %{<select #{o.html.to_xml_attributes }>}
          out << %{#{options_for_select( o.obj, o.meth, options )}}
          out << %{</select>}
        end
        
        # Creates an input tag with the given +option+ hash as xml/html attributes
        def input_tag( options )
          %{<input #{options.to_xml_attributes }/>}
        end
        
        # Creates an select tag that is not nesiscarily bound to an objects value
        # === Options
        # +name+ The name of the select tag
        # +range+ A range or array that specifies the values of the options
        # +default+ The default value.  This will be selected if present
        # +txt+ A parrallel array of text values
        def select_tag(name, range, default, txt = nil)
          out = %{<select name="#{name}">\n}
          range.each_with_index do |value, index |
            out << option_for_select( value, (txt ? txt[index] : value ), (default == value ) )
          end
          out << "</select>\n"
        end
        
        protected
        
        # Creates a label from the openstruct created in control_for
        def label_for_object( o )
          o.label.nil? ? "" : %{<label for="#{o.html[:id]}">#{o.label}</label>}
        end 
        
        # The gateway to creating options for a select box
        def options_for_select( obj, value_method, options )
          text_method = options[:text_method] || value_method
          collection = options[:collection] || []
          
          out = ""
          out = "<option></option>" if options[:include_blank]
          out << case collection
          when Array
            options_for_select_from_array( obj, collection, value_method, text_method )
          when Hash
            options_for_select_from_hash( obj, collection, value_method, text_method )
          end
        end
        
        def options_for_select_from_array( selected_object, collection, value_method, text_method )
          out = ""
          collection.each do | element|
            out << option_for_select( element.send( value_method ), element.send( text_method ), (selected_object == element) )
          end
          out
        end
        
        def options_for_select_from_hash( selected_object, collection, value_method, text_method )
          out = ""
          collection.keys.sort.each do |key|
            out << %{<optgroup label="#{key.to_s.humanize.titleize}">}
            out << options_for_select_from_array( selected_object, collection[key], value_method, text_method )
            out << %{</optgroup>}
          end
          out
        end
        
        # Creates that actual option tag for any given value, text and selected (true/false) combination
        def option_for_select( value, text, selected )
          out = %{<option#{ selected ? " selected=\"selected\"" : nil } }
          out << %{value="#{value}">#{text}</option>}
        end
      end

    end # Control
  end # FormHelper
end  # Merb
