class MerbGenerator < RubiGen::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name']) unless defined? DEFAULT_SHEBANG
  
  default_options   :shebang => DEFAULT_SHEBANG
  
  attr_reader :name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    @destination_root = File.expand_path(@name)
    extract_options
  end

  def manifest
    script_options     = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }

    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }
      
      # copy skeleton
      m.file_copy_each %w( Rakefile )
      m.file_copy_each %w( application.rb exceptions.rb ), "app/controllers"
      m.file_copy_each %w( global_helper.rb ), "app/helpers"
      m.file_copy_each %w( application.html.erb ), "app/parts/views/layout"      
      m.file_copy_each %w( application.html.erb application.text.erb ), "app/mailers/views/layout"
      m.file_copy_each %w( application.html.erb ), "app/views/layout"
      m.file_copy_each %w( internal_server_error.html.erb not_found.html.erb not_acceptable.html.erb ), "app/views/exceptions"
      m.file_copy_each %w( merb.jpg ), "public/images"
      m.file_copy_each %w( master.css ), "public/stylesheets"
      m.file_copy_each %w( merb.fcgi ), "public"
      m.file_copy_each %w( boot.rb merb_init.rb router.rb upload.conf dependencies.rb), "config"
      m.file_copy_each %w( development.rb production.rb test.rb ), "config/environments"
      m.file_copy_each %w( spec_helper.rb ), "spec"
      m.file_copy_each %w( test_helper.rb), "test"

      # build default config
      m.template "config/merb.yml", "config/merb.yml", :assigns => {:key => "#{@name.upcase}#{rand(9999)}"}
      
      # build scripts
      %w( stop_merb generate destroy ).each do |file|
        m.file     "script/#{file}",        "script/#{file}", script_options
        m.template "script/win_script.cmd", "script/#{file}.cmd", :assigns => { :filename => file } if windows
      end
    end
  end
  
  def windows
    (RUBY_PLATFORM =~ /dos|win32|cygwin/i) || (RUBY_PLATFORM =~ /(:?mswin|mingw)/)
  end
  
  protected
    def banner
      <<-EOS
Creates a Merb application stub.

USAGE: #{spec.name} -g path"
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

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      app/controllers
      app/models
      app/helpers
      app/mailers/helpers
      app/mailers/views/layout
      app/parts/helpers
      app/parts/views/layout
      app/views/layout
      app/views/exceptions
      config/environments
      lib
      log
      public/images
      public/javascripts
      public/stylesheets
      script
      spec/models
      spec/controllers
      test/unit
      gems
    )
    
end
