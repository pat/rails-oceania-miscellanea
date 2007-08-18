module ActionView
  module Helpers
    module CacheHelper
      # Selective fragment caching
      def conditional_cache(conditional, name = {}, &block)
        conditional ? @controller.cache_erb_fragment(block, name) : block.call
      end
    end
  end
end