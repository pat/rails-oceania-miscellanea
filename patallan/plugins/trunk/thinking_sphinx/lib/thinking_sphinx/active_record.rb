require 'thinking_sphinx/active_record/delta'
require 'thinking_sphinx/active_record/search'

module ThinkingSphinx
  # Core additions to ActiveRecord models - define_index for creating indexes
  # for models. If you want to interrogate the index objects created for the
  # model, you can use the class-level accessor :indexes.
  #
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
          # If you want some (integer, float or timestamp) attributes, the
          # syntax is a little different:
          #
          #   define_index do |index|
          #     index.has.created_at
          #     index.has.updated_at
          #   end
          #
          # Please note that attributes can't be requested from associations.
          #
          # One last feature is the delta index. This requires the model to
          # have a boolean field named 'delta', and is enabled as follows:
          #
          #   define_index do |index|
          #     index.delta = true
          #     # usual attributes and fields go here
          #   end
          #
          # In previous versions of Thinking Sphinx, delta indexes were one
          # step behind the most recent record changes. This has since been
          # fixed.
          #
          def define_index(&block)
            @indexes ||= []
            index = Index.new(self, &block)
            
            @indexes << index
            unless ThinkingSphinx.indexed_models.include?(self.name)
              ThinkingSphinx.indexed_models << self.name
            end
            
            if index.delta?
              before_save   :toggle_delta
              after_commit  :index_delta
            end
            
            index
          end
          alias_method :sphinx_index, :define_index
          
          def to_crc32
            result = 0xFFFFFFFF
            self.name.each_byte do |byte|
              result ^= byte
              8.times do
                result = (result >> 1) ^ (0xEDB88320 * (result & 1))
              end
            end
            result ^ 0xFFFFFFFF
          end
        end
      end
      
      base.send(:include, ThinkingSphinx::ActiveRecord::Delta)
      base.send(:include, ThinkingSphinx::ActiveRecord::Search)
    end
  end
end