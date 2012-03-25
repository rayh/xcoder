
module Xcode
  
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
        # @todo I am not sure how this is set; perhaps just the target name
        'remoteInfo' => target_name }
    end
    
  end
end