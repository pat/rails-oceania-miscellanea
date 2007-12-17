module Merb
  module Caching
    module MemcachedStore
    

    def get(name)
      ::Cache.get("fragment:#{name}")
    end
    
    def put(name, content = nil)
      ::Cache.put("fragment:#{name}", content)
      content
    end
    
    def expire_fragment(name)
      ::Cache.delete(name)
    end     
    end
  end
end      