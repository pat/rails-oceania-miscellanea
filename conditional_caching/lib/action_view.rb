module ActionView
  module Helpers
    module CacheHelper
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
end