require 'active_record'

require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/attribute'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'
require 'thinking_sphinx/search'

module ThinkingSphinx
  module Version
    Major = 0
    Minor = 8
    Tiny  = 0
    
    String = [Major, Minor, Tiny].join('.')
  end
  
  class ConnectionError < StandardError #:nodoc:
  end
  
  def self.indexed_models
    @@indexed_models ||= []
  end
  
  def self.indexed_models=(value)
    @@indexed_models = value
  end
end