module ThinkingSphinx
  # Represents an index for Sphinx config. Also performs the core part of SQL
  # query generation - although thankfully ActiveRecord does most of the heavy
  # lifting. Syntax examples for indexes can be found at ActiveRecord#define_index.
  class Index
    attr_accessor :model, :fields
    
    # Create a new index, passing in the model it is for.
    def initialize(model)
      @model = model
      @fields = []
    end
    
    # Add a new field to the index
    def includes(*args)
      @fields << Field.new(self, args.empty? ? nil : args)
      @fields.last
    end
        
    # This method grabs all the fields, combines all their associations, and
    # generates usable SQL for the Sphinx configuration file. It makes heavy
    # use of ActiveRecord's Join SQL code - thankfully saving me from going
    # insane.
    def to_sql
      associations = {}
      @fields.each { |field| associations[field.unique_name] = field.associations }
      
      level = 0
      next_assocs = associations.collect { |key,value| value[level] }.compact.uniq
      base_dependency = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(@model, [], nil)
      joins = []
      
      @fields.each do |field|
        parent_join = base_dependency.joins.first
        field.associations.each do |assoc|
          if existing = joins.detect { |join| join.reflection == assoc.reflection }
            parent_join = existing
          else
            joins << ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.new(assoc.reflection, base_dependency, parent_join)
            parent_join = joins.last
          end
        end
        field.prefix = field.associations.empty? ? @model.table_name : joins.last.aliased_table_name
      end
      
      join_statement  = joins.collect { |join| join.association_join }.join(" ")
      field_select    = @fields.collect { |field| field.select_clause }.join(", ")
      group_statement = @fields.collect { |field| field.group_clause }.flatten.compact.uniq.join(", ")
      
      "SELECT #{@model.table_name}.#{@model.primary_key}, '#{@model}' AS class, #{field_select} FROM #{@model.table_name} #{join_statement} WHERE #{@model.table_name}.#{@model.primary_key} >= $start AND #{@model.table_name}.#{@model.primary_key} <= $end GROUP BY #{group_statement}"
    end
    
    # Simple helper method for the query info SQL
    def sql_query_info
      "SELECT * FROM #{@model.table_name} WHERE #{@model.primary_key} = $id"
    end
    
    # Simple helper method for the query range SQL
    def sql_query_range
      "SELECT MIN(#{@model.primary_key}), MAX(#{@model.primary_key}) FROM #{@model.table_name}"
    end
  end
end