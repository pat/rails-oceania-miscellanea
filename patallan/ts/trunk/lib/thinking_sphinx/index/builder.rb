module ThinkingSphinx
  class Index
    class Builder
      class << self
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
          end
        end
        alias_method :field, :indexes
        
        def has(*args)
          options = args.extract_options!
          args.each do |column|
            column = FauxColumn.new(column) if column.is_a?(Symbol)
            attributes << Attribute.new(column, options)
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