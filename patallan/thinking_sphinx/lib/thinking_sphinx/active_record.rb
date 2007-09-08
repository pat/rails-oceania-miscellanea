module ThinkingSphinx
  module ActiveRecord
    def self.included(base)
      base.class_eval do
        class << self
          attr_accessor :indexes
          
          def define_index(&block)
            @indexes ||= []
            @indexes << Index.new(self)
            yield @indexes.last
            ThinkingSphinx.indexed_models << self
            @indexes.last
          end
          
          def search(params={})
            search_string = params.select { |key,value|
              !value.blank?
            }.collect { |key,value|
              "@#{key} #{value}"
            }.join(" & ")
            
            sphinx = ThinkingSphinx::Client.new
            sphinx.match_mode = :extended
            
            result = sphinx.query(search_string)
            puts result.inspect
            result[:matches].collect { |id,value|
              find id
            }
          end
        end
      end
    end
  end
end