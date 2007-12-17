class MerbPluginGenerator < RubiGen::Base
  attr_reader :name
  
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])
  
  
  def initialize(args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift.gsub(/-/,"_")
    @destination_root = File.expand_path(@name)
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      m.directory "lib/#{name}"
      m.directory "spec"
      
      m.template "Rakefile", "Rakefile", :assigns => {:name => name}
      m.template "README", "README", :assigns => {:name => name}

      m.template "LICENSE", "LICENSE"
      m.template "TODO", "TODO", :assigns => {:name => name}
      
      m.file "spec_helper.rb", "spec/spec_helper.rb"

      m.template "sampleplugin_spec.rb", "spec/#{name}_spec.rb", :assigns => {:name => name}
      m.template "sampleplugin.rb", "lib/#{name}.rb", :assigns => {:name => name}
      m.template "merbtasks.rb", "lib/#{name}/merbtasks.rb", :assigns => {:name => name}
    end
  end
  
  protected
    def banner
      <<-EOS
Creates a Merb plugin stub.

USAGE: #{spec.name} --generate-plugin path"
EOS
    end

    def add_options!(opts)
      # opts.separator ''
      # opts.separator 'Options:'
      # # For each option below, place the default
      # # at the top of the file next to "default_options"
      # opts.on("-r", "--ruby=path", String,
      #        "Path to the Ruby binary of your choice (otherwise scripts use env, dispatchers current path).",
      #        "Default: #{DEFAULT_SHEBANG}") { |options[:shebang]| }
      # opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end
    
    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end

end
