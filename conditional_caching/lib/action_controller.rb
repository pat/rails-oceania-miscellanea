# Changes and additions to ActionController
module ActionController
  class Base
    # This method allows blocks to be passed directly to the caches_action
    # method. I'm not a fan of the syntax (ie. it's not obvious that the block
    # is for determining whether the action is cached), and I don't like
    # completely overwriting the default Rails method.
    # def self.caches_action(*actions, &block)
    #   return unless perform_caching
    #   around_filter(ActionCacheFilter.new(*actions, &block))
    # end 
    
    # A method for checking if a cached fragment exists when a certain
    # condition is true. The first parameter is that condition, the rest are
    # the normal parameters for
    # ActionController::Caching::Fragments.read_fragment
    #
    # ==== Examples
    # A default call, the equivalent of read_fragment()
    # 
    #   if conditional_read_fragment(@current_user.nil?)
    #     # code that should not be run if there's a cache
    #   end
    #
    # Passing additional caching params works in the same way
    # 
    #   if conditional_read_fragment(@current_user.nil?, :page => params[:page])
    #     # ...
    #   end
    def conditional_read_fragment(conditional, name, options = nil)
      return read_fragment(name, options) if conditional
    end
  end
  
  module Caching
    module Actions
      class ActionCacheFilter
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
          unless @check = (@options.delete(:if) || @block)
            return default_before(controller)
          end
          
          case @check
          when Symbol
            return default_before(controller) if controller.send(@check)
          when Proc
            return default_before(controller) if controller.instance_eval(&@check)
          end
        end
        
        alias_method :default_after, :after
        
        def after(controller) #:nodoc:
          case @check
          when nil
            return default_after(controller)
          when Symbol
            return default_after(controller) if controller.send(@check)
          when Proc
            return default_after(controller) if controller.instance_eval(&@check)
          else
            return true
          end
        end
      end
    end
  end
end