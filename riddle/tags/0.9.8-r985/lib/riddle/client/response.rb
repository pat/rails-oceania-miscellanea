module Riddle
  class Client
    # Used to interrogate responses from the Sphinx daemon. Keep in mind none
    # of the methods here check whether the data they're grabbing are what the
    # user expects - it just assumes the user knows what the data stream is
    # made up of.
    class Response
      # Create with the data to interpret
      def initialize(str)
        @str = str
        @marker = 0
      end
      
      # Return the next string value in the stream
      def next
        len = next_int
        result = @str[@marker, len]
        @marker += len
        
        return result
      end
      
      # Return the next integer value from the stream
      def next_int
        int = @str[@marker, 4].unpack('N*').first
        @marker += 4
        
        return int
      end
      
      # Return the next float value from the stream
      def next_float
        float = @str[@marker, 4].unpack('N*').pack('L').unpack('f*').first
        @marker += 4
        
        return float
      end
      
      # Returns an array of string items
      def next_array
        count = next_int
        items = []
        for i in 0...count
          items << self.next
        end
        
        return items
      end
      
      # Returns an array of int items
      def next_int_array
        count = next_int
        items = []
        for i in 0...count
          items << self.next_int
        end
        
        return items
      end
      
      # Returns the length of the streamed data
      def length
        @str.length
      end
    end
  end
end