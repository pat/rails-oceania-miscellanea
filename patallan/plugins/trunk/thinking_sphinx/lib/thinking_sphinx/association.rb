module ThinkingSphinx
  class Association
    attr_accessor :parent, :reflection, :join
    
    def initialize(parent, reflection)
      @parent, @reflection = parent, reflection
      @children = {}
    end
    
    def children(assoc)
      @children[assoc] ||= Association.children(@reflection.klass, assoc, self)
    end
    
    def self.children(klass, assoc, parent=nil)
      ref = klass.reflect_on_association(assoc)
      return [] if ref.nil?
      
      unless ref.options[:polymorphic]
        return [Association.new(parent, ref)]
      end
      
      polymorphic_classes(ref).collect { |klass|
        Association.new parent, ::ActiveRecord::Reflection::AssociationReflection.new(
          ref.macro,
          "#{ref.name}_#{klass.name}".to_sym,
          casted_options(klass, ref),
          ref.active_record
        )
      }
    end
    
    def join_to(base_join)
      parent.join_to(base_join) if parent && parent.join.nil?
      
      @join ||= ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.new(
        @reflection, base_join, parent ? parent.join : base_join.joins.first
      )
    end
    
    def to_sql
      @join.association_join.gsub(/::ts_join_alias::/,
        "`#{@join.parent.aliased_table_name}`"
      )
    end
    
    def is_many?
      case @reflection.macro
      when :has_many, :has_and_belongs_to_many
        true
      else
        @parent ? @parent.is_many? : false
      end
    end
    
    def ancestors
      (parent ? parent.ancestors : []) << self
    end
    
    private
    
    def self.polymorphic_classes(ref)
      ref.active_record.connection.select_all(
        "SELECT DISTINCT #{ref.options[:foreign_type]} " +
        "FROM #{ref.active_record.table_name} " +
        "WHERE #{ref.options[:foreign_type]} IS NOT NULL"
      ).collect { |row|
        row[ref.options[:foreign_type]].constantize
      }
    end
    
    def self.casted_options(klass, ref)
      options = ref.options.clone
      options[:polymorphic]   = nil
      options[:class_name]    = klass.name
      options[:foreign_key] ||= "#{ref.name}_id"
      
      foreign_type = ref.options[:foreign_type]
      case options[:conditions]
      when nil
        options[:conditions] = "::ts_join_alias::.`#{foreign_type}` = '#{klass.name}'"
      when Array
        options[:conditions] << "::ts_join_alias::.`#{foreign_type}` = '#{klass.name}'"
      when Hash
        options[:conditions].merge!(foreign_type => klass.name)
      else
        options[:conditions] << " AND `::ts_join_alias::.#{foreign_type}` = '#{klass.name}'"
      end
      
      options
    end
  end
end