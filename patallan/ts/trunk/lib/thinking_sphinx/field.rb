module ThinkingSphinx
  class Field
    attr_accessor :alias, :columns, :sortable, :associations, :model
    
    def initialize(columns, options)
      @columns      = Array(columns)
      @associations = {}
      
      @alias        = options[:as]
      @sortable     = options[:sortable] || false
    end
    
    def to_select_sql
      clause = @columns.collect { |column|
        column_with_prefix(column)
      }.join(', ')
      
      if associations.values.flatten.length > 1
        clause = "CONCAT_WS(' ', #{clause})"
      end
      
      if is_many?
        "CAST(GROUP_CONCAT(#{clause} SEPARATOR ' ') AS CHAR) AS `#{unique_name}`"
      else
        "CAST(#{clause} AS CHAR) AS `#{unique_name}`"
      end
    end
    
    def to_group_sql
      is_many? ? nil : @columns.collect { |column|
        column_with_prefix(column)
      }
    end
    
    private
    
    def unique_name
      if @columns.length == 1
        @alias || @columns.first.__name
      else
        @alias
      end
    end
    
    def column_with_prefix(column)
      if associations[column].empty?
        "`#{@model.table_name}`.`#{column.__name}`"
      else
        associations[column].collect { |assoc|
          "`#{assoc.join.aliased_table_name}`.`#{column.__name}`"
        }.join(', ')
      end
    end
    
    def is_many?
      associations.values.flatten.any? { |assoc| assoc.is_many? }
    end
  end
end