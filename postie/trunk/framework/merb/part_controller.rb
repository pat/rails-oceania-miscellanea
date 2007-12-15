module Merb
  class PartController < AbstractController
    self._template_root = File.expand_path(self._template_root / "../parts/views")
    include Merb::WebControllerMixin
    
    def initialize(web_controller)
      @web_controller = web_controller
      super
    end

    def dispatch(action=:to_s)
      old_action = params[:action]
      params[:action] = action
      super(action)
      params[:action] = old_action
      @_body
    end    
  end
end    