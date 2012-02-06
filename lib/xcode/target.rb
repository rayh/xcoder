module Xcode
  
  #
  # Within a project a user may define a number of targets. These targets may
  # be to generate the application, generate a universal framework, or execute
  # tests.
  # 
  module Target
    
    # A reference to the project for which these targets reside.
    attr_accessor :project
    
    #
    # @return [PBXBuildConfiguration] the configurations that this target supports.
    #   these are generally 'Debug' or 'Release' but may be custom designed
    #   configurations.
    # 
    def configs
      buildConfigurationList.buildConfigurations.map do |config|
        config.target = self
        config
      end
    end
    
    #
    # Return a specific build configuration. When one is not found to match,
    # an exception is raised.
    # 
    # @param [String] name of a configuration to return
    # @return [PBXBuildConfiguration] a specific build configuration that 
    #   matches the specified name.
    #
    def config(name)
      config = configs.select {|config| config.name == name.to_s }.first
      raise "No such config #{name}, available configs are #{configs.map {|c| c.name}.join(', ')}" if config.nil?
      yield config if block_given?
      config
    end
    
  end
  
end