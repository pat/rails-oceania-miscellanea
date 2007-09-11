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
          # return the ids for the matching objects.
          #
          def search_for_ids(params={})
            search_string = params.merge(:class => self.name).select { |key,value|
              !value.blank?
            }.collect { |key,value|
              "@#{key} #{value}"
            }.join(" & ")
            
            sphinx = ThinkingSphinx::Client.new
            sphinx.match_mode = :extended
            
            sphinx.query(search_string)[:matches]
          end
          
          # Searches for results that match the parameters provided. These
          # parameter keys should match the names of fields in the indexes.
          #
          # Example:
          #
          #   Invoice.find :customer => "Pat"
          #
          def search(params={})
            search_for_ids(params).collect { |id,value|
              find id
            }
          end
        end
      end
    end
  end
end