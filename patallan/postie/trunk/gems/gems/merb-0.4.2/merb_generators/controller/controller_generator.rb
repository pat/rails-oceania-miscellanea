require 'merb/generators/merb_generator_helpers'

class ControllerGenerator < Merb::GeneratorHelpers::ControllerGeneratorBase

  def initialize(*args)
    runtime_options = args.last.is_a?(Hash) ? args.pop : {}
    name, *actions = args.flatten
    runtime_options[:actions] = actions.empty? ? %w[index] : actions
    super( [name], runtime_options  )
  end
  
  def self.superclass
    RubiGen::Base
  end
    
end