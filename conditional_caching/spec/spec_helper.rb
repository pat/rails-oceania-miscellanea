ENV["RAILS_ENV"] = "test"

require 'fileutils'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view'
require "action_caching"
require "fragment_caching"

FILE_STORE_PATH = File.join(File.dirname(__FILE__), "tmp/cache")
ActionController::Base.cache_store = :file_store, FILE_STORE_PATH
ActionController::Base.perform_caching = true
ActionController::Base.logger = nil

Spec::Runner.configure do |config|
  config.include ActionController::TestProcess
  
  config.before :all do
    FileUtils.mkdir_p(FILE_STORE_PATH)
  end
  
  config.before :each do
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
    @request.host = 'hostname.com'
  end
  
  config.after :all do
    FileUtils.rm_r(FILE_STORE_PATH) if File.exists?(FILE_STORE_PATH)
  end
end

def be_cached
  CacheMatcher.new
end

class CacheMatcher
  def matches?(request)
    @full_path = File.join(FILE_STORE_PATH, request.host + 
      request.env["REQUEST_URI"] + ".cache")
    File.exist?(@full_path)
  end
  
  def failure_message
    "Cache file at \"#{@full_path}\" was expected, but does not exist"
  end
  
  def negative_failure_message
    "Cache file at \"#{@full_path}\" was not expected, but does exist"
  end
end