
module Xcode
  
  #
  # Within a Target Dependency there is a ContainerItemProxy object which likely
  # holds the reference to the project (important if there are multiple projects)
  # and the target within that project.
  # 
  # @see TargetDependency#create_dependency_on
  # @see Target#add_dependency
  # 
  module ContainerItemProxy
    
    # 
    # Generate default properties for a Container Item Proxy
    # 
    # @see TargetDependency
    # 
    #     /* Begin PBXContainerItemProxy section */
    #         98A30E0314CDF2D800DF81EF /* PBXContainerItemProxy */ = {
    #           isa = PBXContainerItemProxy;
    #           containerPortal = 0867D690FE84028FC02AAC07 /* Project object */;
    #           proxyType = 1;
    #           remoteGlobalIDString = 98A1E39414CDED2C00D4AB9D; /* Target in the Project */
    #           remoteInfo = "Facebook Framework";
    #         };
    #     /* End PBXContainerItemProxy section */
    # 
    def self.default(project_identifier,target_identifier,target_name)
      { 'isa' => 'PBXContainerItemProxy',
        'containerPortal' => project_identifier,
        'proxyType' => 1,
        'remoteGlobalIDString' => target_identifier,
        # @todo It is unclear if the remoteInfo name is necessary and it is currently
        #   unclear to me how this value is set. At the moment it simply set with
        #   the target name supplied.
        'remoteInfo' => target_name }
    end
    
  end
end