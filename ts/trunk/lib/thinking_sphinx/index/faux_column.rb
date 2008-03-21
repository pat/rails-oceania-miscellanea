module ThinkingSphinx
  class Index
    class FauxColumn
      def initialize(*stack)
        @name  = stack.pop
        @stack = stack
      end
      
      # Can't use normal method name, as that could be an association or
      # column name.
      def __name
        @name
      end
      
      # Can't use normal method name, as that could be an association or
      # column name.
      def __stack
        @stack
      end
      
      def method_missing(method, *args)
        @stack << @name
        @name   = method
        
        if (args.empty?)
          self
        elsif (args.length == 1)
          method_missing(args.first)
        else
          args.collect { |arg|
            FauxColumn.new(@stack + [@name, arg])
          }
        end
      end
    end
  end
end