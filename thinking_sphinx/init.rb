require 'thinking_sphinx'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)
