require 'rubygems'
require 'optparse'
require 'ostruct'
require 'fileutils'
require 'yaml'
require 'merb/erubis_ext'

require File.join(File.dirname(__FILE__), 'version')

module Merb

  class Config
    class << self
      def defaults
        @defaults ||= {
          :host                   => "0.0.0.0",
          :port                   => "4000",
          :reloader               => true,
          :cache_templates        => false,
          :merb_root              => Dir.pwd,
          :use_mutex              => true,
          :session_id_cookie_only => true,
          :query_string_whitelist => [],
          :mongrel_x_sendfile     => true
        }
      end

      def setup(global_merb_yml = nil)
        if FileTest.exist? "#{defaults[:merb_root]}/framework"
          $LOAD_PATH.unshift( "#{defaults[:merb_root]}/framework" )
        end
        global_merb_yml ||= "#{defaults[:merb_root]}/config/merb.yml"
        apply_configuration_from_file defaults, global_merb_yml
      end

      def apply_configuration_from_file(configuration, file)
        if File.exists?(file)
          configuration.merge(Erubis.load_yaml_file(file))
        else
          configuration
        end
      end
    end
  end
  
  class Server
    
    class << self
      
      def merb_config(argv = ARGV)
        # Our primary configuration hash for the length of this method
        options = {}
        
        # Environment variables always win
        options[:environment] = ENV['MERB_ENV']

        # Build a parser for the command line arguements
        opts = OptionParser.new do |opts|
          opts.version = Merb::VERSION
          opts.release = Merb::RELEASE
          
          opts.banner = "Usage: merb [fdcepghmisluMG] [argument]"
          opts.define_head "Merb Mongrel+ Erb. Lightweight replacement for ActionPack."
          opts.separator '*'*80
          opts.separator 'If no flags are given, Merb starts in the foreground on port 4000.'
          opts.separator '*'*80

          opts.on("-u", "--user USER", "This flag is for having merb run as a user other than the one currently logged in. Note: if you set this you must also provide a --group option for it to take effect.") do |config|
            options[:user] = config
          end

          opts.on("-G", "--group GROUP", "This flag is for having merb run as a group other than the one currently logged in. Note: if you set this you must also provide a --user option for it to take effect.") do |config|
            options[:group] = config
          end
                    
          opts.on("-f", "--config-file FILENAME", "This flag is for adding extra config files for things like the upload progress module.") do |config|
            options[:config] = config
          end
          
          opts.on("-d", "--daemonize", "This will run a single merb in the background.") do |config|
            options[:daemonize] = true
          end
          
          opts.on("-c", "--cluster-nodes NUM_MERBS", "Number of merb daemons to run.") do |nodes|
            options[:cluster] = nodes
          end
      
          opts.on("-p", "--port PORTNUM", "Port to run merb on, defaults to 4000.") do |port|
            options[:port] = port
          end

          opts.on("-h", "--host HOSTNAME", "Host to bind to (default is all IP's).") do |host|
            if host
              options[:host] = host
            else
              # If no host was given, assume they meant they wanted help.
              puts opts  
              exit
            end
          end
      
          opts.on("-m", "--merb-root MERB_ROOT", "The path to the MERB_ROOT for the app you want to run (default is current working dir).") do |merb_root|
            options[:merb_root] = File.expand_path(merb_root)
          end
          
          opts.on("-i", "--irb-console", "This flag will start merb in irb console mode. All your models and other classes will be available for you in an irb session.") do |console|
            options[:console] = true
          end
          
          opts.on("-s", "--start-drb PORTNUM", "This is the port number to run the drb daemon on for sessions and upload progress monitoring.") do |drb_port|
            options[:start_drb] = true
            options[:only_drb] = true
            options[:drb_server_port] = drb_port
          end
          
          opts.on("-l", "--log-level LEVEL", "Log levels can be set to any of these options: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN") do |loglevel|
            options[:log_level] = loglevel
          end
          
          opts.on("-e", "--environment STRING", "Run merb in the correct mode(development, production, testing)") do |env|
            options[:environment] ||= env
          end
          
          opts.on("-r", "--script-runner ['RUBY CODE'| FULL_SCRIPT_PATH]", 
            "Command-line option to run scripts and/or code in the merb app.") do |stuff_to_run|
            options[:runner] = stuff_to_run
          end

          opts.on("-g", "--generate-app PATH", "Generate a fresh merb app at PATH.") do |path|
            options[:generate] = path || Dir.pwd
          end

          opts.on("-P","--generate-plugin PATH", "Generate a fresh merb plugin at PATH.") do |path|
            options[:generate_plugin] = path || Dir.pwd
          end

          opts.on("-k", "--kill PORT or all", "Kill one merb proceses by port number.  Use merb -k all to kill all merbs.") do |ports|
            options[:kill] = ports
          end

          opts.on("-K", "--graceful PORT or all", "Gracefully kill one merb proceses by port number.  Use merb -K all to gracefully kill all merbs.") do |ports|
            options[:graceful] = ports
          end
          
          opts.on("-M", "--merb-config FILENAME", "This flag is for explicitly declaring the merb app's config file.") do |config|
            options[:merb_config] = config
          end
          
          opts.on("-w", "--webrick", "Run merb using Webrick Rack Adapter instead of mongrel.") do |webport|
            options[:webrick] = true
          end
          
          opts.on("-F", "--fastcgi", "Run merb using FastCGI Rack Adapter instead of mongrel.") do
            options[:fastcgi] = true
          end
          
          opts.on("-X", "--mutex on/off", "This flag is for turning the mutex lock on and off.") do |mutex|
            if mutex == 'off'
              options[:use_mutex] = false
            else
              options[:use_mutex] = true
            end   
          end
          
          opts.on("-?", "-H", "--help", "Show this help message") do
            puts opts  
            exit
          end
        end

        # Parse what we have on the command line
        opts.parse!(argv)

        # merb <argument> is same as merb -g <argument>
        if argv.size == 1
          options[:generate] = File.expand_path(argv.last)
        end
        
        # Load up the configuration from file, but keep the command line
        # options that may have been chosen. Also, pass-through if we have
        # a new merb_config path.
        options = Merb::Config.setup(options[:merb_config]).merge(options)

        # Finally, if all else fails... set the environment to 'development'
        options[:environment] ||= 'development'
        
        environment_merb_yml = "#{options[:merb_root]}/config/environments/#{options[:environment]}.yml"        
        options = Merb::Config.apply_configuration_from_file options, environment_merb_yml

        @@merb_opts = options
      end

      def max_mtime( files = [] )
        files.map{ |file| File.mtime(file) rescue @mtime }.max
      end
      
      def register_session_type(name, file, description = nil)
        @registered_session_types ||= YAML::Omap.new
        @registered_session_types[name] = {
          :file => file,
          :description => (description || "Using #{name} sessions")
        }
      end
      
      def add_controller_mixins
        types = @registered_session_types
        Merb::Controller.class_eval do
          lib = File.join(__DIR__, 'merb')
          session_store = Merb::Server.config[:session_store].to_s
          if ["", "false"].include?(session_store)
            puts "Not Using Sessions"
          elsif reg = types[session_store]
            if session_store == "cookie" 
              unless @@merb_opts[:session_secret_key] && (@@merb_opts[:session_secret_key].length >= 16)
                puts("You must specify a session_secret_key in your merb.yml, and it must be at least 16 characters\nbailing out...")
                exit! 
              end
              Merb::Controller.session_secret_key = @@merb_opts[:session_secret_key]
            end
            require reg[:file]
            include ::Merb::SessionMixin
            puts reg[:description]
          else
            puts "Session store not found, '#{Merb::Server.config[:session_store]}'."
            puts "Defaulting to CookieStore Sessions"
            unless @@merb_opts[:session_secret_key] && (@@merb_opts[:session_secret_key].length >= 16)
              puts("You must specify a session_secret_key in your merb.yml, and it must be at least 16 characters\nbailing out...")
              exit! 
            end            
            Merb::Controller.session_secret_key = @@merb_opts[:session_secret_key]
            require types['cookie'][:file]
            include ::Merb::SessionMixin
            puts "(plugin not installed?)"
          end
          
          if Merb::Server.config[:basic_auth]
            require lib + "/mixins/basic_authentication"
            include ::Merb::AuthenticationMixin
            puts "Basic Authentication mixed in"
          end
        end
      end

      def initialize_merb
        require 'merb'
        @mtime = Time.now if @@merb_opts[:reloader] == true
        # Register session types before merb_init.rb so that any additional
        # session stores will be added to the end of the list and become the
        # default.
        register_session_type('memory',
          __DIR__ / "merb" / "session" / "memory_session",
          "Using in-memory sessions; sessions will be lost whenever the server stops.")
        register_session_type('mem_cache',
          __DIR__ / "merb" / "session" / "mem_cache_session",
          "Using MemCache distributed memory sessions")
        register_session_type('cookie', # Last session type becomes the default
          __DIR__ / "merb" / "session" / "cookie_store",
          "Using 'share-nothing' cookie sessions (4kb limit per client)")
        require @@merb_opts[:merb_root] / 'config/merb_init.rb'
        add_controller_mixins
      end
      
      def after_app_loads(&block)
        @after_app_blocks ||= []
        @after_app_blocks << block
      end
      
      def app_loaded?
        @app_loaded
      end
      
      def load_action_arguments(klasses = Merb::Controller._subclasses)
        begin
          klasses.each do |controller|
            controller = Object.full_const_get(controller)
            controller.action_argument_list = {}
            controller.callable_actions.each do |action, bool|
              controller.action_argument_list[action.to_sym] = ParseTreeArray.translate(controller, action).get_args
            end
          end
        rescue
          klasses.each { |controller| controller.action_arguments = {} }
        end if defined?(ParseTreeArray)
      end
      
      def template_paths(type = "*")
        # This gets all templates set in the controllers template roots        
        template_paths = Merb::AbstractController._abstract_subclasses.map do |klass| 
          Object.full_const_get(klass)._template_root
        end.uniq.map do |path| 
          Dir["#{path}/**/#{type}"] 
        end
        
        # This gets the templates that might be created outside controllers
        # template roots.  eg app/views/shared/*
        template_paths << Dir["#{MERB_ROOT}/app/views/**/*"] if type == "*"
        
        template_paths.flatten.compact.uniq || []
      end
      
      def load_controller_template_path_cache
        Merb::AbstractController.reset_template_path_cache!

        template_paths.each do |template|
          Merb::AbstractController.add_path_to_template_cache(template)
        end
      end
      
      def load_erubis_inline_helpers
        partials = template_paths("_*.erb")

        partials.each do |partial|
          eruby = Erubis::Eruby.new(File.read(partial))
          eruby.def_method(Merb::GlobalHelper, partial.gsub(/[^\.a-zA-Z0-9]/, "__").gsub(/\./, "_"), partial)
        end        
      end
      
      def load_application
        MERB_PATHS.each do |glob|
          Dir[MERB_ROOT + glob].each { |m| require m }
        end
        load_action_arguments
        load_controller_template_path_cache
        load_erubis_inline_helpers
        @app_loaded = true
        (@after_app_blocks || []).each { |b| b.call }
      end
      
      def remove_constant(const)
        parts = const.to_s.split("::")
        base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
        object = parts[-1].intern
        MERB_LOGGER.info("Removing constant #{object} from #{base}")
        base.send(:remove_const, object) if object
        Merb::Controller._subclasses.delete(const)
      end

      def reload
        return if !@@merb_opts[:reloader] || !Object.const_defined?(:MERB_PATHS)
        
        # First we collect all files in the project (this will also grab newly added files)
        project_files = MERB_PATHS.map { |path| Dir[@@merb_opts[:merb_root] + path] }.flatten.uniq
        erb_partials = template_paths("_*.erb").map { |path| Dir[path] }.flatten.uniq
        project_mtime = max_mtime(project_files + erb_partials) # Latest changed time of all project files

        return if @mtime.nil? || @mtime >= project_mtime   # Only continue if a file has changed

        project_files.each do |file|
          if File.mtime(file) >= @mtime
            # If the file has changed or been added since the last project reload time
            # remove any cannonical constants, based on what type of project file it is
            # and then reload the file
            begin
              constant = case file
                when %r[/app/(models|controllers|parts|mailers)/(.+)\.rb$]
                  $2.to_const_string
                when %r[/app/(helpers)/(.+)\.rb$]
                  "Merb::" + $2.to_const_string
                end
                remove_constant(constant)
            rescue NameError => e
              MERB_LOGGER.warn "Couldn't remove constant #{constant}"
            end
            
            begin
              MERB_LOGGER.info("Reloading file #{file}")
              old_subclasses = Merb::Controller._subclasses.dup
              load(file)
              loaded_classes = Merb::Controller._subclasses - old_subclasses
              load_action_arguments(loaded_classes)
            rescue Exception => e
              puts "Error reloading file #{file}: #{e}"
              MERB_LOGGER.warn "  Error: #{e}"
            end
            
            # constant = file =~ /\/(controllers|models|mailers|helpers|parts)\/(.*).rb/ ? $2.to_const_string : nil
            # remove_constant($2.to_const_string, ($1 == "helpers") ? Merb : nil)
            # load file and puts "loaded file: #{file}"
          end
        end        

        # Rebuild the glob cache and erubis inline helpers
        load_controller_template_path_cache
        load_erubis_inline_helpers

        @mtime = project_mtime # As the last action, update the current @mtime
      end

      def run
        @@merb_raw_opts = ARGV
        merb_config

        if @@merb_opts[:generate] #|| @@merb_opts.size == 1
          require 'merb/generators/merb_app/merb_app'
          ::Merb::AppGenerator.run @@merb_opts[:generate]
          exit!
        end  
       
        if ENV['EVENT'] || ENV['SWIFT']
          @@merb_opts[:use_mutex] = false 
        end
        
        if @@merb_opts[:graceful]
          @@merb_opts[:kill] = @@merb_opts[:graceful]
          graceful = true
        end

        if k = @@merb_opts[:kill]
          begin
            Dir[@@merb_opts[:merb_root] + "/log/merb.#{k == 'all' ? '*' : k }.pid"].each do |f|
              puts f
              pid = IO.read(f).chomp.to_i
              signal = graceful ? 1 : 9
              Process.kill(signal, pid)
              FileUtils.rm f
              puts "killed PID #{pid} with signal #{signal}"
            end
          rescue
            puts "Failed to kill! #{k}"
          ensure  
            exit
          end
        end  
        
        case @@merb_opts[:environment].to_s
        when 'production'
          @@merb_opts[:reloader] = @@merb_opts.fetch(:reloader, false)
          @@merb_opts[:exception_details] = @@merb_opts.fetch(:exception_details, false)
          @@merb_opts[:cache_templates] = true
        else
          @@merb_opts[:reloader] = @@merb_opts.fetch(:reloader, true)
          @@merb_opts[:exception_details] = @@merb_opts.fetch(:exception_details, true)
        end
        
        @@merb_opts[:reloader_time] ||= 0.5 if @@merb_opts[:reloader] == true
        
        $LOAD_PATH.unshift( File.join(@@merb_opts[:merb_root] , '/app/models') )
        $LOAD_PATH.unshift( File.join(@@merb_opts[:merb_root] , '/app/controllers') )
        $LOAD_PATH.unshift( File.join(@@merb_opts[:merb_root] , '/lib') )

        if @@merb_opts[:generate_plugin]
          require 'merb/generators/merb_plugin'
          ::Merb::PluginGenerator.run @@merb_opts[:generate_plugin]
          exit!
        end  
        
        if @@merb_opts[:reloader]
          Thread.abort_on_exception = true
          Thread.new do
            loop do
              sleep( @@merb_opts[:reloader_time] )
              reload if app_loaded?
            end
            Thread.exit
          end
        end
        
        if @@merb_opts[:console]
          initialize_merb
          _merb = Class.new do
            def self.show_routes(all_opts = false)
              seen = []
              unless Merb::Router.named_routes.empty?
                puts "Named Routes"
                Merb::Router.named_routes.each do |name,route|
                  puts "  #{name}: #{route}"
                  seen << route
                end
              end
              puts "Anonymous Routes"
              (Merb::Router.routes - seen).each do |route|
                puts "  #{route}"
              end
              nil
            end
            
            def self.url(path, *args)
              Merb::Router.generate(path,*args)
            end
          end
          
          Object.send(:define_method, :merb) {
            _merb
          }  
            
          ARGV.clear # Avoid passing args to IRB 
          require 'irb' 
          require 'irb/completion' 
          def exit
            exit!
          end   
          if File.exists? ".irbrc"
            ENV['IRBRC'] = ".irbrc"
          end
          IRB.start
          exit!
        end

        if @@merb_opts[:runner]
          initialize_merb
          code_or_file = @@merb_opts[:runner] 
          if File.exists?(code_or_file)
            eval(File.read(code_or_file))
          else
            eval(code_or_file)
          end
          exit!
        end
        
        if @@merb_opts[:start_drb] 
          puts "Starting merb drb server on port: #{@@merb_opts[:drb_server_port]}"
          start(@@merb_opts[:drb_server_port], :drbserver_start)
          exit if @@merb_opts[:only_drb]
        end  
        
        if @@merb_opts[:webrick] 
          puts "Starting merb webrick server on port: #{@@merb_opts[:port]}"
          trap('TERM') { exit }
          webrick_start(@@merb_opts[:port])
        end
        
        if @@merb_opts[:fastcgi] 
          trap('TERM') { exit }
          fastcgi_start
        end
        
        
        if @@merb_opts[:cluster]
          delete_pidfiles
          @@merb_opts[:port].to_i.upto(@@merb_opts[:port].to_i+@@merb_opts[:cluster].to_i-1) do |port|
            puts "Starting merb server on port: #{port}"
            start(port)
          end   
        elsif @@merb_opts[:daemonize]
          delete_pidfiles(@@merb_opts[:port])
          start(@@merb_opts[:port])
        else
          trap('TERM') { exit }
          mongrel_start(@@merb_opts[:port])
        end     
      
      end
      
      def store_pid(pid,port)
        File.open("#{@@merb_opts[:merb_root]}/log/merb.#{port}.pid", 'w'){|f| f.write("#{Process.pid}\n")}
      end  
      
      def start(port,what=:mongrel_start)
        fork do
          Process.setsid
          exit if fork
          if what == :mongrel_start
            store_pid(Process.pid, port)
          else
            store_pid(Process.pid, "drb.#{port}")
          end
          Dir.chdir @@merb_opts[:merb_root]
          File.umask 0000
          STDIN.reopen "/dev/null"
          STDOUT.reopen "/dev/null", "a"
          STDERR.reopen STDOUT
          trap("TERM") { exit }
          send(what, port)
        end
      end
      
      def webrick_start(port)
        initialize_merb
        require 'rack'
        require 'merb/rack_adapter'
        ::Rack::Handler::WEBrick.run Merb::Rack::Adapter.new,
          :Port => port
      end

      def fastcgi_start
        initialize_merb
        require 'rack'
        require 'merb/rack_adapter'
        ::Rack::Handler::FastCGI.run Merb::Rack::Adapter.new
      end
      
      def delete_pidfiles(portor_star='*')
        Dir["#{@@merb_opts[:merb_root]}/log/merb.#{portor_star}.pid"].each do |pid|
          FileUtils.rm(pid)  rescue nil
        end
      end  
      
      def drbserver_start(port)
        puts "Starting merb drb server on port: #{port}"
        require 'merb/merb_drb_server'
        drb_init = File.join(@@merb_opts[:merb_root], "/config/merb_drb_init")
        require drb_init if File.exist?(drb_init)
        DRb.start_service("druby://#{@@merb_opts[:host]}:#{port}", Merb::DrbServiceProvider)
        DRb.thread.join
      end  
      
      def mongrel_start(port)
        @@merb_opts[:port] = port
        unless  @@merb_opts[:generate] ||  @@merb_opts[:console] ||  @@merb_opts[:only_drb] ||  @@merb_opts[:kill]
          puts %{Merb started with these options:}
          puts @@merb_opts.to_yaml; puts
        end
        initialize_merb
      
        mconf_hash = {:host => (@@merb_opts[:host]||"0.0.0.0"), :port => (port ||4000)}
        if @@merb_opts[:user] and @@merb_opts[:group]
          mconf_hash[:user]   = @@merb_opts[:user]
          mconf_hash[:group]  = @@merb_opts[:group]
        end
        mconfig = Mongrel::Configurator.new(mconf_hash) do
          listener do
            uri( "/", :handler => MerbUploadHandler.new(@@merb_opts), :in_front => true) if @@merb_opts[:upload_path_match]
            uri "/", :handler => MerbHandler.new(@@merb_opts[:merb_root]+'/public', @@merb_opts[:mongrel_x_sendfile])
            uri "/favicon.ico", :handler => Mongrel::Error404Handler.new("") 
          end
          MerbHandler.path_prefix = @@merb_opts[:path_prefix]
      
          trap("INT") { stop }
          run
        end
        mconfig.join
      end  
      
      def config
        @@merb_opts
      end 
      
    end # class << self
    
  end # Server

end # Merb
