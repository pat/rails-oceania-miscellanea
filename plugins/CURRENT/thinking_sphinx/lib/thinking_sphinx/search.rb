module ThinkingSphinx
  # Once you've got those indexes in and built, this is the stuff that matters
  # - how to search! This class provides a generic search interface - which you
  # can use to search all your indexed models at once. Most times, you will
  # just want a specific model's results - to search and search_for_ids methods
  # will do the job in exactly the same manner when called from a model.
  # 
  class Search
    class << self
      # Searches for results that match the parameters provided. Will only
      # return the ids for the matching objects. See #search for syntax
      # examples.
      #
      def search_for_ids(*args)
        results, client = search_results(*args.clone)
        
        begin
          pager = WillPaginate::Collection.new(page,
            client.limit, results[:total])
          pager.replace results[:matches].collect { |match| match[:doc] }
        rescue
          results[:matches].collect { |match| match[:doc] }
        end
      end

      # Searches through the Sphinx indexes for relevant matches. There's
      # various ways to search, sort, group and filter - which are covered
      # below.
      #
      # Also, if you have WillPaginate installed, the search method can be used
      # just like paginate. The same parameters - :page and :per_page - work as
      # expected, and the returned result set can be used by the will_paginate
      # helper.
      # 
      # == Basic Searching
      #
      # The simplest way of searching is straight text.
      # 
      #   ThinkingSphinx::Search.search "pat"
      #   ThinkingSphinx::Search.search "google"
      #   User.search "pat", :page => (params[:page] || 1)
      #   Article.search "relevant news issue of the day"
      #
      # If you specify :include, like in an #find call, this will be respected
      # when loading the relevant models from the search results.
      # 
      #   User.search "pat", :include => :posts
      #
      # == Searching by Fields
      # 
      # If you want to step it up a level, you can limit your search terms to
      # specific fields:
      # 
      #   User.search :conditions => {:name => "pat"}
      #
      # This uses Sphinx's extended match mode, unless you specify a different
      # match mode explicitly (but then this way of searching won't work). Also
      # note that you don't need to put in a search string.
      #
      # == Searching by Attributes
      #
      # Also known as filters, you can limit your searches to documents that
      # have specific values for their attributes. This is done _exactly_ like
      # limiting words to certain fields:
      #
      #   ThinkingSphinx::Search.search :conditions => {:parent_id => 10}
      #
      # Filters can be single values, arrays of values, or ranges.
      # 
      #   Article.search "East Timor", :conditions => {:rating => 3..5}
      #
      # == Sorting
      #
      # Sphinx can only sort by attributes - but if you specify a field as
      # sortable, you can use field names, and Thinking Sphinx will interpret
      # accordingly, but only if you use the 'order' option - like a #find
      # call.
      #
      #   Location.search "Melbourne", :order => :state
      #   User.search :conditions => {:role_id => 2}, :order => "name ASC"
      #
      # Keep in mind that if you use a string, you *must* specify the direction
      # (ASC or DESC) else Sphinx won't return any results. If you use a symbol
      # then Thinking Sphinx assumes ASC, but if you wish to state otherwise,
      # use the :sort_mode option:
      #
      #   Location.search "Melbourne", :order => :state, :sort_mode => :desc
      #
      # Of course, there are other sort modes - check out the Sphinx
      # documentation[http://sphinxsearch.com/doc.html] for that level of
      # detail though.
      #
      # == Grouping
      # 
      # For this you can use the group_by, group_clause and group_function
      # options - which are all directly linked to Sphinx's expectations. No
      # magic from Thinking Sphinx. It can get a little tricky, so make sure
      # you read all the relevant
      # documentation[http://sphinxsearch.com/doc.html#clustering] first.
      # 
      # Yes this section will be expanded, but this is a start.
      #
      def search(*args)
        results, client = search_results(*args.clone)
        
        ::ActiveRecord::Base.logger.error(
          "Sphinx Error: #{results[:error]}"
        ) if results[:error]
        
        options = args.extract_options!
        klass   = options[:class]
        page    = options[:page] ? options[:page].to_i : 1
        
        begin
          pager = WillPaginate::Collection.new(page,
            client.limit, results[:total] || 0)
          pager.replace results[:matches].collect { |match|
            instance_from_result match, options, klass
          }
        rescue StandardError => err
          results[:matches].collect { |match|
            instance_from_result match, options, klass
          }
        end
      end
      
      private
      
      # This method handles the common search functionality, and returns both
      # the result hash and the client. Not super elegant, but it'll do for
      # the moment.
      # 
      def search_results(*args)
        options = args.extract_options!
        client  = client_from_options options
        
        query, filters    = search_conditions(
          options[:class], options[:conditions] || {}
        )
        client.filters   += filters
        client.match_mode = :extended unless query.empty?
        query             = args.join(" ") + query
        
        set_sort_options! client, options
        
        client.limit  = options[:per_page].to_i if options[:per_page]
        page          = options[:page] ? options[:page].to_i : 1
        client.offset = (page - 1) * client.limit

        begin
          ::ActiveRecord::Base.logger.debug "Sphinx: #{query}"
          results = client.query query
        rescue Errno::ECONNREFUSED => err
          raise ThinkingSphinx::ConnectionError, "Connection to Sphinx Daemon (searchd) failed."
        end
        
        return results, client
      end
      
      # Either use the provided class to instantiate a result from a model, or
      # get the result's CRC value and determine the class from that.
      # 
      def instance_from_result(result, options, klass = nil)
        (klass ? klass : class_from_crc(result[:attributes]["class_crc"])).find(
          result[:doc], :include => options[:include]
        )
      end
      
      # Convert a CRC value to the corresponding class.
      # 
      def class_from_crc(crc)
        unless @models_by_crc
          Configuration.new.load_models
          
          @models_by_crc = ThinkingSphinx.indexed_models.inject({}) do |hash, model|
            hash[model.constantize.to_crc32] = model
            hash
          end
        end
        
        @models_by_crc[crc].constantize
      end
      
      # Set all the appropriate settings for the client, using the provided
      # options hash.
      # 
      def client_from_options(options)
        config = ThinkingSphinx::Configuration.new
        client = Riddle::Client.new "localhost", config.port
        klass  = options[:class]
        index_options = klass ? klass.indexes.last.options : {}
        
        [
          :max_matches, :sort_mode, :sort_by, :id_range, :group_by,
          :group_function, :group_clause, :group_distinct, :cut_off,
          :retry_count, :retry_delay, :index_weights, :rank_mode,
          :max_query_time, :field_weights, :filters, :anchor, :limit
        ].each do |key|
          client.send(
            key.to_s.concat("=").to_sym,
            options[key] || index_options[key] || client.send(key)
          )
        end
        
        client.anchor = anchor_conditions(klass, options) || {} if client.anchor.empty?
        
        client
      end
      
      # Translate field and attribute conditions to the relevant search string
      # and filters.
      # 
      def search_conditions(klass, conditions={})
        attributes = klass ? klass.indexes.collect { |index|
          index.attributes.collect { |attrib| attrib.unique_name }
        }.flatten : []
        
        search_string = ""
        filters       = []
        
        conditions.each do |key,val|
          if attributes.include?(key.to_sym)
            filters << Riddle::Client::Filter.new(
              key.to_s,
              val.is_a?(Range) ? val : Array(val)
            )
          else
            search_string << "@#{key} #{val} "
          end
        end
        
        filters << Riddle::Client::Filter.new(
          "class_crc", [klass.to_crc32]
        ) if klass
        
        return search_string, filters
      end
      
      # Return the appropriate latitude and longitude values, depending on
      # whether the relevant attributes have been defined, and also whether
      # there's actually any values.
      # 
      def anchor_conditions(klass, options)
        attributes = klass ? klass.indexes.collect { |index|
          index.attributes.collect { |attrib| attrib.unique_name }
        }.flatten : []
        
        lat_attr = klass ? klass.indexes.collect { |index|
          index.options[:latitude_attr]
        }.compact.first : nil
        
        lon_attr = klass ? klass.indexes.collect { |index|
          index.options[:longitude_attr]
        }.compact.first : nil
        
        lat_attr = options[:latitude_attr] if options[:latitude_attr]
        lat_attr ||= :lat       if attributes.include?(:lat)
        lat_attr ||= :latitude  if attributes.include?(:latitude)
        
        lon_attr = options[:longitude_attr] if options[:longitude_attr]
        lon_attr ||= :lon       if attributes.include?(:lon)
        lon_attr ||= :long      if attributes.include?(:long)
        lon_attr ||= :longitude if attributes.include?(:longitude)
        
        lat = options[:lat]
        lon = options[:lon]
        
        if options[:geo]
          lat = options[:geo].first
          lon = options[:geo].last
        end
        
        lat && lon ? {
          :latitude_attribute   => lat_attr,
          :latitude             => lat,
          :longitude_attribute  => lon_attr,
          :longitude            => lon
        } : nil
      end
      
      # Set the sort options using the :order key as well as the appropriate
      # Riddle settings.
      # 
      def set_sort_options!(client, options)
        klass = options[:class]
        fields = klass ? klass.indexes.collect { |index|
          index.fields.collect { |field| field.unique_name }
        }.flatten : []
        
        case order = options[:order]
        when Symbol
          client.sort_mode ||= :attr_asc
          if fields.include?(order)
            client.sort_by = order.to_s.concat("_sort")
          else
            client.sort_by = order.to_s
          end
        when String
          client.sort_mode = :extended
          client.sort_by   = sorted_fields_to_attributes(order, fields)
        else
          # do nothing
        end
      end
      
      # Search through a collection of fields and translate any appearances
      # of them in a string to their attribute equivalent for sorting.
      # 
      def sorted_fields_to_attributes(string, fields)
        fields.each { |field|
          string.gsub!(/(^|\s)#{field}(,?\s|$)/) { |match|
            match.gsub field.to_s, field.to_s.concat("_sort")
          }
        }
        
        string
      end
    end
  end
end