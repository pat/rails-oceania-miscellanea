require 'merb/generators/merb_generator_helpers'
class MerbModelTestGenerator < Merb::GeneratorHelpers::MerbModelTestGenerator
  
  def initialize( *args )
    super( *args )
    @model_test_template_name = "model_test_unit_template.erb"
    @model_test_path_name = File.join( "test", "unit" )
    @model_test_file_suffix = "test"
  end
  
    def banner
            <<-EOS
Creates a model Test::Unit stub for use in Merb

USAGE: #{$0} #{spec.name} NameOfModel
Example:
  #{$0} #{spec.name} project


      EOS
    end
  
  def self.superclass
    RubiGen::Base
  end
end

class MerbTesterThing
end