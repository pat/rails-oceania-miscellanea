module ThinkingSphinx
  class Field
    attr_accessor :index, :column, :associations, :prefix
    
    def initialize(index, column=nil)
      @index, @column = index, column
      @associations = []
      @expecting_as = false
    end
    
    def as(as=nil)
      as.nil? ? @expecting_as = true : @as = as
      self
    end
    
    def unique_name
      @as || @column
    end
    
    def many?
      associations.any? { |assoc| [:has_many, :has_and_belongs_to_many].include?(assoc.reflection.macro) }
    end
    
    def method_missing(method, *args)
      if args.empty? and @expecting_as
        @as = method
        @expecting_as = false
        return self
      end
      
      model = (associations.last || index).model
      raise ArgumentError.new if model.nil?
      
      if model.columns_hash[method.to_s].nil?
        reflection = model.reflect_on_association(method)
        raise ArgumentError.new("Model #{model.name} does not have an attribute or association called #{method}") if reflection.nil?
        
        @associations << Association.new(self, method, reflection)
      else
        @column = method
      end
      
      return self if args.empty?
      fields = args.collect { |arg| method_missing(arg) }
      fields.length == 1 ? fields.first : self
    end
  end
end