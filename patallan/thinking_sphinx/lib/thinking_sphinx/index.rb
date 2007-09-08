module ThinkingSphinx
  class Index
    attr_accessor :model, :fields
    
    def initialize(model)
      @model = model
      @fields = []
    end
    
    def includes(*args)
      if args.empty?
        @fields << Field.new(self)
        return @fields.last
      end
      
      args.each { |arg| @fields << Field.new(self, arg) }
      args.length == 1 ? @fields.last : self
    end
    
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
      
      join_statement = joins.collect { |join| join.association_join }.join(" ")
      
      field_select = @fields.collect { |field|
        if field.many?
          "CAST(GROUP_CONCAT(#{field.prefix}.#{field.column} SEPARATOR ' ') AS CHAR) AS #{field.unique_name}"
        else
          "CAST(#{field.prefix}.#{field.column} AS CHAR) AS #{field.unique_name}"
        end
      }.join(", ")
      
      group_statement = (["#{@model.table_name}.#{@model.primary_key}"] + fields.select { |field|
        !field.many?
      }.collect { |field| "#{field.prefix}.#{field.column}" }).uniq.join(", ")
      
      "SELECT #{@model.table_name}.#{@model.primary_key}, '#{@model}' AS class, #{field_select} FROM #{@model.table_name} #{join_statement} WHERE #{@model.table_name}.#{@model.primary_key} >= $start AND #{@model.table_name}.#{@model.primary_key} <= $end GROUP BY #{group_statement}"
    end
    
    def sql_query_info
      "SELECT * FROM #{@model.table_name} WHERE #{@model.primary_key} = $id"
    end
    
    def sql_query_range
      "SELECT MIN(#{@model.primary_key}), MAX(#{@model.primary_key}) FROM #{@model.table_name}"
    end
  end
end