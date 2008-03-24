module ThinkingSphinx
  module ActiveRecord
    module Search
      def self.included(base)
        base.class_eval do
          class << self
            # Searches for results that match the parameters provided. Will only
            # return the ids for the matching objects. See #search for syntax
            # examples.
            #
            def search_for_ids(*args)
              options = args.extract_options!
              client  = client_from_options options
              
              query, filters    = search_conditions(options[:conditions] || {})
              client.filters   += filters
              client.match_mode = :extended unless query.empty?
              query             = args.join(" ") + query
              
              set_sort_options! client, options
              
              client.limit  = options[:per_page].to_i if options[:per_page]
              page          = options[:page] ? options[:page].to_i : 1
              client.offset = (page - 1) * client.limit

              begin
                logger.debug "Sphinx: #{query}"
                results = client.query query, self.name.downcase
              rescue Errno::ECONNREFUSED => err
                raise ThinkingSphinx::ConnectionError, "Connection to Sphinx Daemon (searchd) failed."
              end

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
              ids = search_for_ids(*args.clone)
              options = args.extract_options!
              
              ids.replace ids.collect { |id|
                find id, :include => options[:include] rescue nil
              }.compact
            end
            
            private
            
            def client_from_options(options)
              config = ThinkingSphinx::Configuration.new
              client = Riddle::Client.new "localhost", config.port
              
              [
                :max_matches, :sort_mode, :sort_by, :id_range, :group_by,
                :group_function, :group_clause, :group_distinct, :cut_off,
                :retry_count, :retry_delay, :index_weights, :rank_mode,
                :max_query_time, :field_weights, :filters, :anchor, :limit
              ].each do |key|
                client.send(
                  key.to_s.concat("=").to_sym,
                  options[key] || indexes.last.options[key] || client.send(key)
                )
              end
              
              client
            end
            
            def search_conditions(conditions)
              attributes = indexes.collect { |index|
                index.attributes.collect { |attrib| attrib.unique_name }
              }.flatten
              
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
              
              return search_string, filters
            end
            
            def set_sort_options!(client, options)
              fields = indexes.collect { |index|
                index.fields.collect { |field| field.unique_name }
              }.flatten
              
              case order = options[:order]
              when Symbol
                client.sort_mode = :attr_asc
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
    end
  end
end