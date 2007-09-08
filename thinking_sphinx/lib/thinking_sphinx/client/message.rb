module ThinkingSphinx
  class Client
    class Message
      def initialize
        @message = ""
      end
      
      def append(*args)
        return if args.length == 0
        
        args.each { |arg| @message << arg }
      end
      
      def append_string(str)
        @message << [str.length].pack('N') + str
      end
      
      def append_int(int)
        @message << [int].pack('N')
      end
      
      def append_ints(*ints)
        ints.each { |int| append_int(int) }
      end
      
      def append_array(array)
        append_int(array.length)
        
        array.each { |item| append_string(item) }
      end
      
      def to_s
        @message
      end
    end
  end
end