require_relative 'build_file'

module Xcode
  
  #
  # Within a project a user may define a number of targets. These targets may
  # be to generate the application, generate a universal framework, or execute
  # tests.
  # 
  # 
  # @example Target as Hash
  # 
  #    E21D8AA914E0F817002E56AA /* newtarget */ = {
  #        isa = PBXNativeTarget;
  #        buildConfigurationList = E21D8ABD14E0F817002E56AA /* Build configuration list for PBXNativeTarget "newtarget" */;
  #        buildPhases = (
  #          E21D8AA614E0F817002E56AA /* Sources */,
  #          E21D8AA714E0F817002E56AA /* Frameworks */,
  #          E21D8AA814E0F817002E56AA /* Resources */,
  #        );
  #        buildRules = (
  #        );
  #        dependencies = (
  #        );
  #        name = newtarget;
  #        productName = newtarget;
  #        productReference = E21D8AAA14E0F817002E56AA /* newtarget.app */;
  #        productType = "com.apple.product-type.application";
  #      };
  #   
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
    
    #
    # A ruby-friendly alias for the property defined at buildPhases.
    # 
    def build_phases
      buildPhases
    end
    
    # 
    # @return [BuildPhase] the framework specific build phase of the target.
    # 
    def framework_build_phase
      build_phases.find {|phase| phase.isa == 'PBXFrameworksBuildPhase' }
    end
    
    #
    # @return [BuildPhase] the sources specific build phase of the target.
    # 
    def sources_build_phase
      build_phases.find {|phase| phase.isa == 'PBXSourcesBuildPhase' }
    end
    
    #
    # @return [BuildPhase] the resources specific build phase of the target.
    # 
    def resources_build_phase
      build_phases.find {|phase| phase.isa == 'PBXResourcesBuildPhase' }
    end
    
  end
  
end