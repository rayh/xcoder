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
  # @todo provide more targets, based on the properties hash generated from Xcode
  # 
  module Target
    
    #
    # This is a generic properties hash for an ios target
    # @todo this target should create by default the sources, frameworks, and 
    #   resources build phases.
    # 
    def self.ios
      { 'isa' => 'PBXNativeTarget',
        'buildConfigurationList' => nil,
        'buildPhases' => [],
        'buildRules' => [],
        'dependencies' => [],
        'name' => '',
        'productName' => '',
        'productReference' => '',
        'productType' => 'com.apple.product-type.application' }
    end
    
    # A reference to the project for which these targets reside.
    attr_accessor :project
    
    #
    # @return [PBXBuildConfiguration] the configurations that this target supports.
    #   these are generally 'Debug' or 'Release' but may be custom designed
    #   configurations.
    # 
    def configs
      build_configuration_list.build_configurations.map do |config|
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
    # Create a configuration for the target.
    # 
    # @example debug configuration
    # 
    #   target.create_config 'Debug' do |config|
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

    def create_configurations(*configuration_names)
      
      configuration_names.compact.flatten.map do |config_name|
        created_config = create_configuration config_name do |config|
          yield config if block_given?
        end
        
        created_config.save!
      end
      
    end
    
    # 
    # @return [BuildPhase] the framework specific build phase of the target.
    # 
    def framework_build_phase
      build_phase 'PBXFrameworksBuildPhase'
    end
    
    #
    # @return [BuildPhase] the sources specific build phase of the target.
    # 
    def sources_build_phase
      build_phase 'PBXSourcesBuildPhase'
    end
    
    #
    # @return [BuildPhase] the resources specific build phase of the target.
    # 
    def resources_build_phase
      build_phase 'PBXResourcesBuildPhase'
    end
    
    def build_phase(type)
      build_phases.find {|phase| phase.isa == type }
    end
    #
    # @example building the three main phases for a target.
    # 
    #     target.create_build_phase :sources
    # 
    #     target.create_build_phase :resources do |phase|
    #       # each phase that is created.
    #     end
    # 
    # @param [String] phase_name the name of the phase to add to the target
    # @return [BuildPhase] the BuildPhase that is created
    def create_build_phase(phase_name)
      
      # Register a BuildPhase with the default properties specified by the name.
      build_phase = @registry.add_object(BuildPhase.send("#{phase_name}"))
      
      # Add the build phase to the list of build phases for this target.
      # @todo this is being done commonly in the application in multiple places
      #   and it bugs me. Perhaps some special module could be mixed into the
      #   Array of results that are returned.
      @properties['buildPhases'] << build_phase.identifier
      
      yield build_phase if block_given?
      
      build_phase.save!
    end
    
    # 
    # Create multiple build phases at the same time.
    # 
    # @param [Array<String,Symbol>] base_phase_names are the names of the phases
    #   that you want to create for a target.
    # 
    # @return [Array] the phases created. 
    #
    def create_build_phases *base_phase_names
      
      base_phase_names.compact.flatten.map do |phase_name|
        build_phase = create_build_phase phase_name do |build_phase|
          yield build_phase if block_given?
        end
        
        build_phase.save!
      end
      
    end
    
    #
    # Create a product reference file and add it to the product. This is by
    # default added to the 'Products' group.
    # 
    # @param [String] name of the product reference to add to the product
    # @return [Resource] the product created
    #
    def create_product_reference(name)
      product = project.products_group.create_product_reference(name)
      product_reference = product.identifier
      product
    end
    
  end
  
end