module ThinkingSphinx
  # Additions to ActiveRecord models - define_index for creating indexes for
  # models, and search for querying Sphinx. If you want to interrogate the
  # index objects created for the model, you can use the class-level accessor
  # :indexes.
  module ActiveRecord
    def self.included(base)
      base.class_eval do
        class << self
          attr_accessor :indexes
          
          # Allows creation of indexes for Sphinx. If you don't do this, there
          # isn't much point trying to search (or using this plugin at all,
          # really).
          #
          # An example or two:
          #
          #   define_index do |index|
          #     index.includes(:id).as.model_id
          #     index.includes.name
          #   end
          #
          # You can also grab fields from associations - multiple levels deep
          # if necessary.
          #
          #   define_index do |index|
          #     index.includes.tags.name.as.tag
          #     index.includes.articles.content
          #     index.includes.orders.line_items.product.name.as.product
          #   end
          #
          # And it will automatically concatenate multiple fields:
          #
          #   define_index do |index|
          #     index.includes.author(:first_name, :last_name).as.author
          #   end
          #
          def define_index(&block)
            @indexes ||= []
            @indexes << Index.new(self)
            yield @indexes.last
            ThinkingSphinx.indexed_models << self
            
            if @indexes.last.delta?
              before_save :toggle_delta
              after_save  :index_delta
            end
            
            @indexes.last
          end

          # Searches for results that match the parameters provided. Will only
          # return the ids for the matching objects. See #search for syntax
          # examples.
          #
          def search_for_ids(*args)
            case args.first
            when String
              str     = args[0]
              options = args[1] || {}
            when Hash
              options = args[0]
              str     = options[:conditions]
            end
            
            str = str.merge(:class => self.name).collect { |key,value|
              value.blank? ? nil : "@#{key} #{value}"
            }.compact.uniq.join(" ") if str.is_a?(Hash)
            page = options[:page].nil? ? 1 : options[:page].to_i
            
            configuration     = ThinkingSphinx::Configuration.new
            sphinx            = Riddle::Client.new
            sphinx.port       = configuration.port
            sphinx.match_mode = options[:match_mode] || :extended
            sphinx.limit      = options[:per_page].nil? ? sphinx.limit : options[:per_page].to_i
            sphinx.offset     = (page - 1) * sphinx.limit
            
            if options[:order]
              sphinx.sort_mode  = :extended
              sphinx.sort_by    = options[:order]
            end
            
            begin
              query = "#{str} @class #{self.name}"
              logger.debug "Sphinx: #{query}"
              results = sphinx.query query
            rescue Errno::ECONNREFUSED => err
              raise Riddle::ConnectionError, "Connection to Sphinx Daemon (searchd) failed."
            end
            
            begin
              pager = WillPaginate::Collection.new(page,
                sphinx.limit, results[:total_found])
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
          # Examples:
          #
          #   Invoice.search :conditions => {:customer => "Pat"}
          #   Invoice.search "Pat" # search all fields
          #   Invoice.search "Pat", :page => (params[:page] || 1)
          #
          def search(*args)
            ids = search_for_ids(*args)
            options = args.extract_options!
            ids.replace ids.collect { |id|
              find id, :include => options[:include]
            }
          end
        end
        
        private
        
        def toggle_delta
          self.delta = true
        end
        
        def index_delta
          unless RAILS_ENV == "test"
            configuration = ThinkingSphinx::Configuration.new
            system "indexer --config #{configuration.config_file} --rotate #{self.class.name.downcase}_delta"
          end
          true
        end
      end
    end
  end
end