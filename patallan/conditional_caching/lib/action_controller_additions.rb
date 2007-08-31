module ConditionalFragmentCaching
  module ActionController
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
  
  module ActionView
    # This method acts in much the same way as
    # ActionView::Helpers::CacheHelper.cache - but with the first parameter
    # acting as a flag to whether it should cache the fragment.
    #
    # ==== Examples
    #
    #   <% conditional_cache @current_user.nil? do %>
    #     <!-- view code that will only be cached when @current_user is nil -->
    #   <% end %>
    #
    # Just like the default cache method, it also accepts additional
    # parameters:
    #
    #   <% conditional_cache @current_user.nil?, :page => params[:page] %>
    #     <!-- view code -->
    #   <% end %>
    def conditional_cache(conditional, name = {}, &block)
      conditional ? @controller.cache_erb_fragment(block, name) : block.call
    end
  end
end