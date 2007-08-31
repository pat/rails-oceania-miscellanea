require "action_caching"
require "fragment_caching"

ActionView::Helpers::CacheHelper.send(:include,
  ConditionalFragmentCaching::ActionView)
ActionController::Base.send(:include,
  ConditionalFragmentCaching::ActionController)
ActionController::Caching::Actions::ActionCacheFilter.send(:include,
  ConditionalActionCaching)