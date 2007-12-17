require 'merb/generators/merb_generator_helpers'
class MerbModelTestGenerator < Merb::GeneratorHelpers::MerbModelTestGenerator
  
  def initialize( *args )
    super( *args )
    @model_test_template_name = "model_spec_template.erb"
    @model_test_path_name = File.join("spec", "models")
    @model_test_file_suffix = "spec"
  end
  
  def banner
          <<-EOS
Creates a model spec stub for use in Merb

USAGE: #{$0} #{spec.name} NameOfModel
Example:
  #{$0} #{spec.name} project


    EOS
  end
  
  def self.superclass
    RubiGen::Base
  end
end