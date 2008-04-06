module ThinkingSphinx
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

      # Searches for results that match the parameters provided. These
      # parameter keys should match the names of fields in the indexes.
      #
      # This will use WillPaginate for results if the plugin is installed.
      # The same parameters - :page and :per_page - work as expected, and
      # the returned result set can be used by the will_paginate helper.
      #
      # Please use only specified attributes when ordering results -
      # anything else will make the query fall over.
      #
      # Examples:
      #
      #   Invoice.search :conditions => {:customer => "Pat"}
      #   Invoice.search "Pat" # search all fields
      #   Invoice.search "Pat", :page => (params[:page] || 1)
      #   Invoice.search "Pat", :order => "created_at ASC"
      #   Invoice.search "Pat", :include => :line_items
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
      
      def instance_from_result(result, options, klass = nil)
        (klass ? klass : class_from_crc(result[:attributes]["class_crc"])).find(
          result[:doc], :include => options[:include]
        )
      end
      
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