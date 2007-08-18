module ActionController
  class Base
    # def self.caches_action(*actions, &block)
    #   return unless perform_caching
    #   around_filter(ActionCacheFilter.new(*actions, &block))
    # end 
    
    def conditional_read_fragment(conditional, name, options = nil)
      return read_fragment(name, options) if conditional
    end
  end
  
  module Caching
    module Actions
      class ActionCacheFilter
        # alias_method :default_initialize, :initialize
        # 
        # def initialize(*actions, &block)
        #   @block = block
        #   default_initialize(*actions, &block)
        # end
        
        alias_method :default_before, :before
        
        def before(controller)
          unless check = (@options.delete(:if) || @block)
            return default_before(controller)
          end
          
          case check
          when Symbol
            return default_before(controller) if controller.send(check)
          when Proc
            return default_before(controller) if controller.instance_eval(&check)
          end
        end
      end
    end
  end
end