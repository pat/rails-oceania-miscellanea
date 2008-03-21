module ThinkingSphinx
  class Attribute
    attr_accessor :alias, :column, :associations, :model
    
    def initialize(column, options)
      @column       = column
      @associations = []
      
      @alias        = options[:as]
    end
    
    def to_select_sql
      clause = column_with_prefix
      
      if associations.length > 1
        clause = "CONCAT_WS(',', #{clause})"
      end
      
      if is_many?
        "CAST(GROUP_CONCAT(#{clause} SEPARATOR ',') AS CHAR) AS `#{unique_name}`"
      else
        "#{clause} AS `#{unique_name}`"
      end
    end
    
    def to_group_sql
      is_many? ? nil : column_with_prefix
    end
    
    def to_sphinx_clause
      if @associations.length > 1 || is_many?
        "sql_attr_multi = uint #{unique_name} from field #{unique_name}"
      else
        klass = @associations.first ? @associations.first.klass : @model
        model_column = klass.columns.detect { |col| col.name == @column.__name }
        case model_column.type
        when :datetime
          "sql_attr_timestamp = #{unique_name}"
        when :string
          "sql_attr_str2ordinal = #{unique_name}"
        when :float
          "sql_attr_float = #{unique_name}"
        when :boolean
          "sql_attr_bool = #{unique_name}"
        else
          "sql_attr_uint = #{unique_name}"
        end
      end
    end
    
    private
    
    def unique_name
      @alias || @column.__name
    end
    
    def column_with_prefix
      if associations.empty?
        "`#{@model.table_name}`.`#{@column.__name}`"
      else
        associations.collect { |assoc|
          "`#{assoc.join.aliased_table_name}`.`#{@column.__name}`"
        }.join(', ')
      end
    end
    
    def is_many?
      associations.any? { |assoc| assoc.is_many? }
    end
  end
end