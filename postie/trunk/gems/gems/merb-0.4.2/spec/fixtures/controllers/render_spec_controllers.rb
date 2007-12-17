SPEC_VIEW_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', 'views'))

module Merb
  class Controller
    self._template_root = SPEC_VIEW_ROOT
  end
  class ControllerExceptions::Base
    def self._template_root; SPEC_VIEW_ROOT; end
  end
end

# Fake class so we can render subdirectories of views
class Examples < Merb::Controller

end

module Nested
  class Example < Merb::Controller
  end
end

class FakeModel
  
  def to_json(*args)
    "{'foo':'bar'}"
  end
  
  def to_xml(*args)
    "<foo>bar</foo>"
  end
end

class FakeModelWithArguments
  
  def to_json(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    '[' + args.map { |arg| "'#{arg}'" }.join(',') + ']'
  end
  
  def to_xml(*args)
    options = args.last.is_a?(Hash) ? args.pop.stringify_keys : {}
    options.keys.sort.inject('') do |str, tag|
      str << "<#{tag}>#{options[tag]}</#{tag}>"
    end
  end
  
end

class RenderObjectController < Merb::Controller
  
  def render_object
    provides :xml,:json
    @foo = FakeModel.new
    render @foo
  end
  
  def render_object_with_template
    provides :xml, :js
    @foo = FakeModel.new
    render @foo
  end
    
end

class RenderObjectWithArgumentsController < Merb::Controller
  
  provides :xml, :foo => 'bar'
  provides :json, ['foo', 'bar']
  
  def render_standard
    @foo = FakeModelWithArguments.new
    render @foo
  end
  
  def render_specific
    provides :xml, :foo => 'bar', :biz => 'baz'
    provides :json, ['foo', 'bar', 'baz']
    @foo = FakeModelWithArguments.new
    render @foo
  end
      
end

class RenderObjectWithBlockController < Merb::Controller
  
  provides :xml do |obj, controller|
    obj.to_xml(:foo => controller.class.name)
  end
  
  provides :json do |obj|
    obj.to_json('foo')
  end
  
  def render_standard
    @foo = FakeModelWithArguments.new
    render @foo
  end
  
  def render_specific
    callback = lambda { |obj, controller, method| obj.send(method, controller.class.name, 'foo', 'bar', 'baz', :foo => controller.class.name.upcase) }
    provides :xml, :json, callback
    @foo = FakeModelWithArguments.new
    render @foo
  end
      
end

class ExtensionTemplateController < Merb::Controller
  provides :js, :xml
  def erubis_templates
    render
  end

  def haml_templates
    render
  end

  def markaby_templates
    render
  end

  def old_style_erubis
    render
  end

  def old_style_erubis2
    render
  end

  def old_style_erubis3
    render
  end

  def old_style_haml
    render
  end

  def old_style_markaby
    render
  end

  def old_style_builder
    render
  end

  def index
    render
  end

  def haml_index
    render
  end

  def markaby_index
    render
  end
  
  def render_nested_js
    render :format => :js
  end
  
  def render_nested_xml
    render :format => :xml
  end
  
  def render_multiple_partials
    render
  end

end

Merb::Server.load_action_arguments
Merb::Server.load_controller_template_path_cache
Merb::Server.load_erubis_inline_helpers