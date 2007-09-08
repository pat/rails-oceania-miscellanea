module ThinkingSphinx
  class Association
    attr_accessor :reflection
    
    def initialize(field, name, reflection)
      @field, @name, @reflection = field, name, reflection
    end
    
    def model
      @reflection.klass
    end
    
    def eql?(assoc)
      assoc.reflection == @reflection
    end
    
    def hash
      @reflection.hash
    end
  end
end