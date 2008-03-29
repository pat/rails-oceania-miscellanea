module ThinkingSphinx
  class Attribute
    attr_accessor :alias, :columns, :associations, :model
    
    def initialize(columns, options)
      @columns      = Array(columns)
      @associations = {}
      
      @alias        = options[:as]
      @type         = options[:type]
    end
    
    def to_select_sql
      clause = @columns.collect { |column|
        column_with_prefix(column)
      }.join(', ')
      
      if associations.values.flatten.length > 1
        clause = "CONCAT_WS(' ', #{clause})"
      end
      
      if is_many?
        "CAST(GROUP_CONCAT(#{clause} SEPARATOR ',') AS CHAR) AS `#{unique_name}`"
      elsif type == :datetime
        "UNIX_TIMESTAMP(#{clause}) AS `#{unique_name}`"
      else
        "#{clause} AS `#{unique_name}`"
      end
    end
    
    def to_group_sql
      case
      when is_many?, is_string?
        nil
      else
        @columns.collect { |column|
          column_with_prefix(column)
        }
      end
    end
    
    def to_sphinx_clause
      case type
      when :multi
        "sql_attr_multi = uint #{unique_name} from field"
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
    
    def unique_name
      if @columns.length == 1
        @alias || @columns.first.__name
      else
        @alias
      end
    end
    
    private
    
    def column_with_prefix(column)
      if column.is_string?
        column.__name
      elsif associations[column].empty?
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
    
    def is_string?
      columns.all? { |col| col.is_string? }
    end
    
    def type
      @type ||= case
      when is_many?
        :multi
      when @associations.values.flatten.length > 1
        :string
      else
        klass = @associations.values.flatten.first ? 
          @associations.values.flatten.first.reflection.klass : @model
        klass.columns.detect { |col|
          @columns.collect { |c| c.__name.to_s }.include? col.name
        }.type
      end
    end
  end
end