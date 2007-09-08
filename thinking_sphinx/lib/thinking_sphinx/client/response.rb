module ThinkingSphinx
  class Client
    class Response
      def initialize(str)
        @str = str
        @marker = 0
      end
      
      def next
        len = next_int
        result = @str[@marker, len]
        @marker += len
        
        return result
      end
      
      def next_int
        int = @str[@marker, 4].unpack('N*').first
        @marker += 4
        
        return int
      end
      
      def next_array
        count = next_int
        items = []
        for i in 0...count
          items << self.next
        end
        
        return items
      end
      
      def length
        @str.length
      end
    end
  end
end