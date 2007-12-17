require 'merb'
class MerbControllerTestGenerator < RubiGen::Base
  
  default_options :author => nil
  
  attr_reader :name, :class_name, :file_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    @class_name = @name.camel_case
    @file_name = @name.snake_case
    extract_options
  end

  def manifest
    record do |m|
      m.directory 'test/functional'
      m.template "functional_test.rb", "test/functional/#{file_name}_test.rb"
      
      m.directory 'test/helpers'
      m.template "helper_test.rb", "test/helpers/#{file_name}_helper_test.rb"
    end
  end

  protected
    def banner
      <<-EOS
Creates a test unit stub for a resource controller

USAGE: #{$0} #{spec.name} name"
EOS
    end

    def add_options!(opts)
      # opts.separator ''
      # opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      # opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end
    
    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end
end