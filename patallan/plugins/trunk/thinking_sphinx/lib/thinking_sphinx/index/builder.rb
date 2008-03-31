module ThinkingSphinx
  class Index
    class Builder
      class << self
        # No idea where this is coming from - haven't found it in any
        # documentation. It's not needed though, so it gets undef'd.
        # Hopefully the list of methods that get in the way doesn't get
        # too long.
        undef_method :parent
        
        attr_accessor :fields, :attributes, :properties, :conditions
        
        def setup
          @fields     = []
          @attributes = []
          @properties = {}
          @conditions = []
        end
        
        def indexes(*args)
          options = args.extract_options!
          args.each do |columns|
            columns = FauxColumn.new(columns) if columns.is_a?(Symbol)
            fields << Field.new(columns, options)
            
            if fields.last.sortable
              attributes << Attribute.new(
                columns.collect { |col| col.clone },
                options.merge(
                  :type => :string,
                  :as => fields.last.unique_name.to_s.concat("_sort").to_sym
                )
              )
            end
          end
        end
        alias_method :field,    :indexes
        alias_method :includes, :indexes
        
        def has(*args)
          options = args.extract_options!
          args.each do |columns|
            columns = FauxColumn.new(columns) if columns.is_a?(Symbol)
            attributes << Attribute.new(columns, options)
          end
        end
        alias_method :attribute, :has
        
        def where(*args)
          @conditions += args
        end
        
        def set_property(*args)
          options = args.extract_options!
          if options.empty?
            @properties[args[0]] = args[1]
          else
            @properties.merge!(options)
          end
        end
        alias_method :set_properties, :set_property
        
        def method_missing(method, *args)
          FauxColumn.new(method, *args)
        end
      end
    end
  end
end