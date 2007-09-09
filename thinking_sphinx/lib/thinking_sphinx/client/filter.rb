module ThinkingSphinx
  class Client
    # Used for querying Sphinx.
    class Filter
      attr_accessor :attribute, :values, :exclude
      
      # Attribute name, values (which can be an array or a range), and whether
      # the filter should be exclusive.
      def initialize(attribute, values, exclude)
        @attribute, @values, @exclude = attribute, values, exclude
      end
      
      def exclude?
        self.exclude
      end
      
      # Returns the message for this filter to send to the Sphinx service
      def query_message
        message = Message.new
        
        message.append_string self.attribute
        case self.values
        when Range
          message.append_ints 0, self.values.first, self.values.last
        when Array
          message.append_int self.values.length
          message.append_ints *self.values
        end
        message.append_int self.exclude? ? 1 : 0
        
        message.to_s
      end
    end
  end
end