require 'rubygems'
if ENV['SWIFT']
  begin
    require 'swiftcore/swiftiplied_mongrel'
    puts "Using Swiftiplied Mongrel"
  rescue LoadError
    require 'mongrel'
	puts "SWIFT variable set but not installed - falling back to normal Mongrel"
  end
elsif ENV['EVENT']
  begin
    require 'swiftcore/evented_mongrel' 
    puts "Using Evented Mongrel"
  rescue LoadError
    require 'mongrel'
	puts "EVENT variable set but swiftiply not installed - falling back to normal Mongrel"
  end
elsif ENV['PACKET']
  begin
    require 'packet_mongrel' 
    puts "Using Packet Mongrel"
  rescue LoadError
    require 'mongrel'
	puts "PACKET variable set but packet not installed - falling back to normal Mongrel"
  end
else
 require 'mongrel'
end
require 'fileutils'
require 'merb/erubis_ext'
require 'merb/logger'

require 'set'
autoload :MerbUploadHandler, 'merb/upload_handler'
autoload :MerbHandler, 'merb/mongrel_handler'

require 'merb/version'

module Merb
  autoload :Authentication, 'merb/mixins/basic_authentication'
  autoload :ControllerMixin, 'merb/mixins/controller'
  autoload :ErubisCaptureMixin, 'merb/mixins/erubis_capture'
  autoload :FormControls, 'merb/mixins/form_control'
  autoload :RenderMixin, 'merb/mixins/render'
  autoload :ResponderMixin, 'merb/mixins/responder'
  autoload :ViewContextMixin, 'merb/mixins/view_context'
  autoload :WebControllerMixin, 'merb/mixins/web_controller'
  autoload :GeneralControllerMixin, 'merb/mixins/general_controller'
  autoload :Caching, 'merb/caching'
  autoload :AbstractController, 'merb/abstract_controller'
  autoload :Const, 'merb/constants'
  autoload :Controller, 'merb/controller'
  autoload :Dispatcher, 'merb/dispatcher'
  autoload :DrbServiceProvider, 'drb_server'
  autoload :ControllerExceptions, 'merb/exceptions'
  autoload :MailController, 'merb/mail_controller'
  autoload :Mailer, 'merb/mailer'
  autoload :PartController, 'merb/part_controller'
  autoload :Request, 'merb/request'
  autoload :Router, 'merb/router'
  autoload :Server, 'merb/server'
  autoload :UploadProgress, 'merb/upload_progress'
  autoload :ViewContext, 'merb/view_context'
  autoload :SessionMixin, 'merb/session'
  autoload :Template, 'merb/template'
  autoload :Plugins, 'merb/plugins'
  autoload :Rack,'merb/rack_adapter'

  # Set up Merb::Server.config[] as an accessor for @@merb_opts
  class Server
    class << self
      def config() @@merb_opts ||= {} end
    end  
  end
  
  # Set up default generator scope
  GENERATOR_SCOPE = [:merb_default, :merb, :rspec]
end

def __DIR__; File.dirname(__FILE__); end
lib = File.join(__DIR__, 'merb')
require File.join(__DIR__, 'merb/core_ext')

unless Object.const_defined?('MERB_ENV')
  MERB_ENV = Merb::Server.config[:environment].nil? ? ($TESTING ? 'test' : 'development') : Merb::Server.config[:environment]
end

MERB_FRAMEWORK_ROOT = __DIR__
MERB_ROOT = Merb::Server.config[:merb_root] || Dir.pwd
MERB_VIEW_ROOT = MERB_ROOT / "app/views"
MERB_SKELETON_DIR = File.join(MERB_FRAMEWORK_ROOT, '../app_generators/merb/templates')
logpath = if $TESTING
           "#{MERB_ROOT}/log/merb_test.log"
          elsif !(Merb::Server.config[:daemonize] || Merb::Server.config[:cluster] )
            STDOUT
          else
            "#{MERB_ROOT}/log/merb.#{Merb::Server.config[:port]}.log"
          end
FileUtils.mkdir_p(File.dirname(logpath)) if logpath.is_a?(String)
MERB_LOGGER = Merb::Logger.new(logpath)
MERB_LOGGER.level = Merb::Logger.const_get(Merb::Server.config[:log_level].upcase) rescue Merb::Logger::INFO
MERB_PATHS = [ 
  "/app/models/**/*.rb",
  "/app/controllers/application.rb",
  "/app/controllers/**/*.rb",
  "/app/helpers/**/*.rb",
  "/app/mailers/**/*.rb",
  "/app/parts/**/*.rb",
  "/config/router.rb"
  ]

if $TESTING
  test_files = File.join(lib, 'test', '*.rb')
  Dir[test_files].each { |file| require file }
end

# If we're in the TEST environment or if running from Rake make sure to load 
# config/merb.yml - which is normally done by Merb::Server.run
Merb::Server.load_config if $TESTING || $RAKE_ENV

# If you don't use the JSON gem, disable auto-parsing of json params too
if Merb::Server.config[:disable_json_gem]
  Merb::Request::parse_json_params = false
else
  begin
    require 'json/ext'
  rescue LoadError
    puts "Using pure ruby JSON lib"
    require 'json/pure'
  end
end