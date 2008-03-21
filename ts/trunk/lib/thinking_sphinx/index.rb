require 'thinking_sphinx/index/builder'
require 'thinking_sphinx/index/faux_column'

module ThinkingSphinx
  class Index
    attr_accessor :model, :fields, :attributes, :conditions, :delta
    
    def initialize(model, &block)
      @model        = model
      @associations = {}
      @fields       = []
      @attributes   = []
      @conditions   = []
      @delat        = false
      
      initialize_from_builder(&block) if block_given?
    end
    
    def to_sql(options={})
      base = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(
        @model, [], nil
      )
      assocs = all_associations(base)
      
      where_clause = ""
      if self.delta?
        where_clause << " AND `#{@model.table_name}`.`delta` = #{options[:delta] ? 1 : 0}"
      end
      unless @conditions.empty?
        where_clause << " AND " << @conditions.join(" AND ")
      end
      
      <<-SQL
SELECT #{ (
  ["`#{@model.table_name}`.`#{@model.primary_key}`"] + 
  @fields.collect { |field| field.to_select_sql } +
  @attributes.collect { |attribute| attribute.to_select_sql }
).join(", ") }
FROM #{@model.table_name}
  #{ assocs.collect { |assoc| assoc.to_sql }.join(' ') }
WHERE `#{@model.table_name}`.`#{@model.primary_key}` >= $start
  AND `#{@model.table_name}`.`#{@model.primary_key}` <= $end
  #{ where_clause }
GROUP BY #{ (
  ["`#{@model.table_name}`.`#{@model.primary_key}`"] + 
  @fields.collect { |field| field.to_group_sql }.compact +
  @attributes.collect { |attribute| attribute.to_group_sql }.compact
).join(", ") }
      SQL
    end
    
    # Simple helper method for the query info SQL
    def to_sql_query_info
      "SELECT * FROM `#{@model.table_name}` WHERE `#{@model.primary_key}` = $id"
    end
    
    # Simple helper method for the query range SQL
    def to_sql_query_range(options={})
      sql = "SELECT MIN(`#{@model.primary_key}`), MAX(`#{@model.primary_key}`) " +
            "FROM `#{@model.table_name}` "
      sql << "WHERE `#{@model.table_name}`.`delta` = #{options[:delta] ? 1 : 0}" if self.delta?
    end
    
    def to_sql_query_pre
      self.delta? ? "UPDATE `#{@model.table_name}` SET `delta` = 0" : ""
    end
    
    def delta?
      @delta
    end
    
    private
    
    def initialize_from_builder(&block)
      builder = Class.new(Builder)
      builder.setup
      
      builder.instance_eval &block
      
      @fields     = builder.fields
      @attributes = builder.attributes
      @conditions = builder.conditions
      @delta      = builder.properties[:delta]
    end
    
    def all_associations(base)
      top_assocs = []
      
      # Create all the association objects and joins
      # - from fields
      top_assocs += @fields.collect { |field|
        field.model ||= @model
        field.columns.collect { |col|
          field.associations[col] ||= associations(col.__stack)
          field.associations[col].each { |assoc| assoc.join_to(base) }
        }.flatten
      }.flatten
      
      # - from associations
      top_assocs += @attributes.collect { |attribute|
        attribute.model ||= @model
        attribute.associations ||= associations(attribute.column.__stack)
        attribute.associations.each { |assoc| assoc.join_to(base) }
      }.flatten
      
      top_assocs.uniq!.collect { |assoc|
        assoc.ancestors
      }.flatten.uniq
    end
    
    def associations(path, parent = nil)
      assocs  = []
      
      if parent.nil?
        assocs = association(path.shift)
      else
        assocs = parent.children(path.shift)
      end
      
      until path.empty?
        point = path.shift
        assocs = assocs.collect { |assoc|
          assoc.children(point)
        }.flatten
      end
      
      assocs
    end
    
    def association(key)
      @associations[key] ||= Association.children(@model, key)
    end
  end
end