require 'thinking_sphinx/active_record'
require 'thinking_sphinx/association'
require 'thinking_sphinx/client'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/field'
require 'thinking_sphinx/index'

module ThinkingSphinx
  def self.indexed_models
    @@indexed_models ||= []
  end
  
  def self.indexed_models=(value)
    @@indexed_models = value
  end
end