module Merb
  module Plugins
    def self.config
      @config ||= File.exists?(MERB_ROOT / "config" / "plugins.yml") ? YAML.load(File.read(MERB_ROOT / "config" / "plugins.yml")) || {} : {}
    end
    
    @rakefiles = []
    def self.rakefiles
      @rakefiles
    end
    
    def self.add_rakefiles(*rakefiles)
      @rakefiles += rakefiles
    end
  end
end