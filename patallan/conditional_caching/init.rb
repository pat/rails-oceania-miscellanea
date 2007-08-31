require "action_controller_additions"
require "action_view_additions"

ActionView::Helpers::CacheHelper.send(:include,
  ConditionalFragmentCaching::ActionView)
ActionController::Base.send(:include,
  ConditionalFragmentCaching::ActionController)
ActionController::Caching::Actions::ActionCacheFilter.send(:include,
  ConditionalActionCaching)