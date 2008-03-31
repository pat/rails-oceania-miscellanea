module ThinkingSphinx
  # Attributes - eternally useful when it comes to filtering, sorting or
  # grouping. This class isn't really useful to you unless you're hacking
  # around with the internals of Thinking Sphinx - but hey, don't let that
  # stop you.
  #
  # One key thing to remember - if you're using the attribute manually to
  # generate SQL statements, you'll need to set the base model, and all the
  # associations. Which can get messy.
  # 
  class Attribute
    attr_accessor :alias, :columns, :associations, :model
    
    # To create a new attribute, you'll need to pass in either a single Column
    # or an array of them, and some (optional) options.
    #
    # Valid options are:
    # - :as   => :alias_name 
    # - :type => :attribute_type
    #
    # Alias is only required in three circumstances: when there's
    # another attribute or column with the same name, when the column name is
    # 'id', or when there's more than one column.
    # 
    # Type is not required, unless you want to force a column to be a certain
    # type (but keep in mind the value will not be CASTed in the SQL
    # statements). The only time you really need to use this is when the type
    # can't be figured out by the column - ie: when not actually using a
    # database column as your source.
    # 
    # Example usage:
    #
    #   Attribute.new(
    #     Column.new(:created_at)
    #   )
    #
    #   Attribute.new(
    #     Column.new(:posts, :id),
    #     :as => :post_ids
    #   )
    #
    #   Attribute.new(
    #     [Column.new(:pages, :id), Column.new(:articles, :id)],
    #     :as => :content_ids
    #   )
    #
    #   Attribute.new(
    #     Column.new("NOW()"),
    #     :as   => :indexed_at,
    #     :type => :datetime
    #   )
    # 
    def initialize(columns, options={})
      @columns      = Array(columns)
      @associations = {}
      
      @alias        = options[:as]
      @type         = options[:type]
    end
    
    # Get the part of the SELECT clause related to this attribute. Don't forget
    # to set your model and attributes first though.
    #
    # This will concatenate strings and arrays of integers, and convert
    # datetimes to timestamps, as needed.
    # 
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
    
    # Get the part of the GROUP BY clause related to this attribute - if one is
    # needed. If not, all you'll get back is nil. The latter will happen if
    # there isn't actually a real column to get data from, or if there's
    # multiple data sources.
    # 
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
    
    # Generates the appropriate attribute statement for a Sphinx configuration
    # file, depending on the attribute's type.
    # 
    def to_sphinx_clause
      case type
      when :multi
        "sql_attr_multi       = uint #{unique_name} from field"
      when :datetime
        "sql_attr_timestamp   = #{unique_name}"
      when :string
        "sql_attr_str2ordinal = #{unique_name}"
      when :float
        "sql_attr_float       = #{unique_name}"
      when :boolean
        "sql_attr_bool        = #{unique_name}"
      else
        "sql_attr_uint        = #{unique_name}"
      end
    end
    
    # Returns the unique name of the attribute - which is either the alias of
    # the attribute, or the name of the only column - if there is only one. If
    # there isn't, there should be an alias. Else things probably won't work.
    # Consider yourself warned.
    # 
    def unique_name
      if @columns.length == 1
        @alias || @columns.first.__name
      else
        @alias
      end
    end
    
    private
    
    # Builds a column reference tied to the appropriate associations. This
    # dives into the associations hash and their corresponding joins to
    # figure out how to correctly reference a column in SQL.
    # 
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
    
    # Could there be more than one value related to the parent record? If so,
    # then this will return true. If not, false. It's that simple.
    # 
    def is_many?
      associations.values.flatten.any? { |assoc| assoc.is_many? }
    end
    
    # Returns true if any of the columns are string values, instead of database
    # column references.
    def is_string?
      columns.all? { |col| col.is_string? }
    end
    
    # Returns the type of the column. If that's not already set, it returns
    # :multi if there's the possibility of more than one value, :string if
    # there's more than one association, otherwise it figures out what the
    # actual column's datatype is and returns that.
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