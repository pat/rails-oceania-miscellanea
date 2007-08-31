module ConditionalActionCaching
  def self.included(mod)
    mod.class_eval do
      attr_accessor :check
      
      # This code allows a block from the caches_action method.
      # See comments above explaining why it's commented out.
      #
      # alias_method :default_initialize, :initialize
      # 
      # def initialize(*actions, &block)
      #   @block = block
      #   default_initialize(*actions, &block)
      # end
      
      alias_method :default_before, :before
      
      # This method, aliased from the default version, will only
      # attempt to cache if there's an :if parameter supplied
      # with the caches_action call. The :if value can be either
      # a Proc or a symbol pointing to an instance method of the
      # controller.
      #
      # ==== Examples
      # Using a symbol:
      #
      #   caches_action :index, :if => :i_can_has_cache?
      #   # ...
      #   def i_can_has_cache?
      #     Time.now.wday == 1 # only cache on Mondays
      #   end
      #
      # Using a Proc:
      #
      #   caches_action :index, :if => Proc.new { Time.now.wday == 1 }
      def before(controller)
        self.check = (@options[:if] || @block)
        
        return default_before(controller) if check?(controller)
      end
      
      alias_method :default_after, :after
      
      def after(controller) #:nodoc:
        return default_after(controller) if check?(controller)
      end
      
      private
      
      def check?(controller)
        case check
        when nil
          true
        when Symbol
          controller.send(check)
        when Proc
          controller.instance_eval(&check)
        else
          false
        end
      end
    end
  end
end