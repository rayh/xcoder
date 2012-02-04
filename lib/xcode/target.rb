module Xcode
  module Target
    
    attr_accessor :project
    
    def configs
      buildConfigurationList.buildConfigurations.map do |config|
        
        class << config
          include Configuration
        end
        
        config.target = self
        config
      end
    end
    
    def config(name)
      config = configs.select {|config| config.name == name.to_s }.first
      raise "No such config #{name}, available configs are #{configs.map {|c| c.name}.join(', ')}" if config.nil?
      yield config if block_given?
      config
    end
    
  end
end