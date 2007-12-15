require 'drb'
require File.dirname(__FILE__)+'/merb_upload_progress'

module Merb
  
  class DrbServiceProvider
    include DRbUndumped
    
    class << self
      
      def upload_progress
        @upload_progress ||= ::Merb::UploadProgress.new
      end
      
    end
    
  end
  
end
