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
            page = (options[:page].to_i || 1)
            
            sphinx = ThinkingSphinx::Client.new
            sphinx.match_mode = options[:match_mode] || :extended
            sphinx.limit      = options[:limit].to_i
            sphinx.offset     = (page - 1) * sphinx.limit
            results           = sphinx.query(str, self.name.downcase)
            
            if const_defined?("WillPaginate")
              pager = WillPaginate::Collection.new(page,
                sphinx.limit, results[:total_found])
              pager.replace results
            else
              results[:matches]
            end
          end
          
          # Searches for results that match the parameters provided. These
          # parameter keys should match the names of fields in the indexes.
          #
          # Examples:
          #
          #   Invoice.find :conditions => {:customer => "Pat"}
          #   Invoice.find "Pat" # search all fields
          #
          def search(*args)
            search_for_ids(*args).collect { |id,value|
              find id
            }
          end
        end
      end
    end
  end
end