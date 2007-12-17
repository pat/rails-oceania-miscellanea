require 'merb'
class MerbControllerTestGenerator < RubiGen::Base
  
  default_options :author => nil
  
  attr_reader :name, :class_name, :file_name, :template_actions
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    @class_name = @name.camel_case
    @file_name = @name.snake_case #.pluralize
    @template_actions = runtime_options[:template_actions] || []
    @engine = runtime_options[:engine] || "erb" # set by subclasses only
    extract_options
  end

  def manifest
    record do |m|
      m.directory 'spec/controllers'
      m.template "controller_spec.rb", "spec/controllers/#{file_name}_spec.rb"
      
      m.directory "spec/views/#{file_name}"
      
      
      # Setup the view stubs for each view
      @template_actions.each do |the_action|  
        template_name = "#{the_action}.html.#{@engine}"
        if File.exists?(File.join(MERB_ROOT, "app", "views", file_name, template_name))
          m.template "#{the_action}_spec.rb", "spec/views/#{file_name}/#{the_action}_html_spec.rb"
        end
      end
      
      
      m.directory 'spec/helpers'
      m.template "helper_spec.rb", "spec/helpers/#{file_name}_helper_spec.rb"
    end
  end

  protected
    def banner
      <<-EOS
Creates a ...

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