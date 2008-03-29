module ThinkingSphinx
  module ActiveRecord
    module Search
      def self.included(base)
        base.class_eval do
          class << self
            # Searches for results that match the parameters provided. Will only
            # return the ids for the matching objects. See #search for syntax
            # examples.
            #
            def search_for_ids(*args)
              options = args.extract_options!
              options[:class] = self
              args << options
              ThinkingSphinx::Search.search_for_ids(*args)
            end

            # Searches for results that match the parameters provided. These
            # parameter keys should match the names of fields in the indexes.
            #
            # This will use WillPaginate for results if the plugin is installed.
            # The same parameters - :page and :per_page - work as expected, and
            # the returned result set can be used by the will_paginate helper.
            #
            # Please use only specified attributes when ordering results -
            # anything else will make the query fall over.
            #
            # Examples:
            #
            #   Invoice.search :conditions => {:customer => "Pat"}
            #   Invoice.search "Pat" # search all fields
            #   Invoice.search "Pat", :page => (params[:page] || 1)
            #   Invoice.search "Pat", :order => "created_at ASC"
            #   Invoice.search "Pat", :include => :line_items
            #
            def search(*args)
              options = args.extract_options!
              options[:class] = self
              args << options
              ThinkingSphinx::Search.search(*args)
            end
          end
        end
      end
    end
  end
end