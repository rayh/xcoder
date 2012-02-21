module Xcode
  module ConfigurationOwner
    
    #
    # @return [Array<BuildConfiguration>] the configurations that this target
    #   or project supports. These are generally 'Debug' or 'Release' but may be 
    #   custom created configurations.
    # 
    def configs
      build_configuration_list.build_configurations.map do |config|
        config.target = self
        config
      end
    end
    
    #
    # Return a specific build configuration. 
    # 
    # @note an exception is raised if no configuration matches the specified name.
    # 
    # @param [String] name of a configuration to return
    # 
    # @return [BuildConfiguration] a specific build configuration that 
    #   matches the specified name.
    #
    def config(name)
      config = configs.select {|config| config.name == name.to_s }.first
      raise "No such config #{name}, available configs are #{configs.map {|c| c.name}.join(', ')}" if config.nil?
      yield config if block_given?
      config
    end
    
    #
    # Create a configuration for the target or project.
    # 
    # @example creating a new 'App Store Submission' configuration for a project
    # 
    #     project.create_config 'App Store Submission' # => Configuration
    # 
    # @example creating a new 'Ad Hoc' configuration for a target
    # 
    #   target.create_config 'Ad Hoc' do |config|
    #     # configuration the new debug config.
    #   end
    # 
    # @param [String] name of the configuration to create
    # @return [BuildConfiguration] that is created
    #
    def create_configuration(name)
      # To create a configuration, we need to create or retrieve the configuration list
      
      created_config = build_configuration_list.create_config(name) do |config|
        yield config if block_given?
      end
      
      created_config
    end
    
    #
    # Create multiple configurations for a target or project.
    # 
    # @example creating 'Release' and 'Debug for a new target
    # 
    #     new_target = project.create_target 'UniversalBinary'
    #     new_target.create_configurations 'Debug', 'Release' do |config|
    #       # set up the configurations
    #     end
    # 
    # @param [String,Array<String>] configuration_names the names of the 
    #   configurations to create.
    #
    def create_configurations(*configuration_names)
      
      configuration_names.compact.flatten.map do |config_name|
        created_config = create_configuration config_name do |config|
          yield config if block_given?
        end
        
        created_config.save!
      end
      
    end
    
  end
  
end