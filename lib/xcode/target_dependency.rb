require 'xcode/container_item_proxy'

module Xcode
  
  #
  # Targets, usually Aggregate targets, have dependencies on other targets. This
  # object manages that relationship. While the class-level default properties 
  # method will return the properties necessary for a target it does not configure
  # it correctly until the method #create_dependency_on is called with the particular
  # target.
  # 
  # @see Target#add_dependency
  # 
  module TargetDependency
    
    #
    # Generate default properties for a Target Dependency
    # 
    #     /* Begin PBXTargetDependency section */
    #         98A30E0414CDF2D800DF81EF /* PBXTargetDependency */ = {
    #           isa = PBXTargetDependency;
    #           target = 98A1E39414CDED2C00D4AB9D /* Facebook */;
    #           targetProxy = 98A30E0314CDF2D800DF81EF /* PBXContainerItemProxy */;
    #         };
    #     /* End PBXTargetDependency section */
    # 
    # @return [Hash] the properties default to a target dependency; however they
    #   are all nil and this properties list is incomplete until the property
    #   values are setup through #create_dependency_on
    # 
    def self.default
      { 'isa' => 'PBXTargetDependency',
        'target' => nil,
        'targetProxy' => nil }
    end
    
    
    #
    # Establish the Target that this Target Dependency is dependent.
    # 
    # @param [Target] target the target this dependency is based on
    #
    def create_dependency_on(target)
      
      @properties['target'] = target.identifier
      
      container_item_proxy = ContainerItemProxy.default target.project.project.identifier, target.identifier, target.name
      container_item_proxy = @registry.add_object(container_item_proxy)
      
      @properties['targetProxy'] = container_item_proxy.identifier
      
      save!
    end
    
  end
end