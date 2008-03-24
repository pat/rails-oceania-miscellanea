module ThinkingSphinx
  module ActiveRecord
    module Delta
      # Code for after_commit callback is written by Eli Miller:
      # http://elimiller.blogspot.com/2007/06/proper-cache-expiry-with-aftercommit.html
      # with slight modification from Joost Hietbrink.
      #
      def self.included(base)
        base.class_eval do
          define_callbacks "after_commit" if respond_to?(:define_callbacks)
          
          class << self
            def after_commit(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(:after_commit, callbacks)
            end
          end
          
          def save_with_after_commit_callback(*args)
            value = save_without_after_commit_callback(*args)
            callback(:after_commit) if value
            return value
          end

          alias_method_chain :save, :after_commit_callback

          def save_with_after_commit_callback!(*args)
            value = save_without_after_commit_callback!(*args)
            callback(:after_commit) if value
            return value
          end

          alias_method_chain :save!, :after_commit_callback

          def destroy_with_after_commit_callback
            value = destroy_without_after_commit_callback
            callback(:after_commit) if value
            return value
          end

          alias_method_chain :destroy, :after_commit_callback

          private

          def toggle_delta
            self.delta = true
          end

          def index_delta
            unless RAILS_ENV == "test"
              configuration = ThinkingSphinx::Configuration.new
              system "indexer --config #{configuration.config_file} --rotate #{self.class.name.downcase}_delta"
            end
            true
          end
        end
      end
    end
  end
end