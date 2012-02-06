module Xcode
  
  #
  # Within the project file the PBXFileReference represents the object 
  # representation to the file on the file sytem. This is usually your source
  # files within your project.
  # 
  module FileReference
    
    # This is the group for which this file is contained within.
    attr_accessor :supergroup
    
    
    def add_to_target target
      
      # First the file needs to have a new entry as a PBXBuildFile
      # E245465314E0756B00082968 /* QuartzCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 406A1B4E1564B7B1C1C1342A /* QuartzCore.framework */; };
      
      build_ident = @registry.add_object 'isa' => "PBXBuildFile",
        'fileRef' => identifier
      
      
      # Second the build file object needs to be added to the Frameworks of the build target
      
      # Build Target
      # 7165D44F146B4EA100DE2F0E /* TestProject */ = {
      # isa = PBXNativeTarget;
      #             buildConfigurationList = 7165D47D146B4EA100DE2F0E /* Build configuration list for PBXNativeTarget "TestProject" */;
      #             buildPhases = (
      #               7165D44C146B4EA100DE2F0E /* Sources */,
      #               7165D44D146B4EA100DE2F0E /* Frameworks */,
      #               7165D44E146B4EA100DE2F0E /* Resources */,
      #             );
      #             buildRules = (
      #             );
      #             dependencies = (
      #             );
      #             name = TestProject;
      #             productName = TestProject;
      #             productReference = 7165D450146B4EA100DE2F0E /* TestProject.app */;
      #             productType = "com.apple.product-type.application";
      #           };
      #       
      
      # the target we have here is the target object and not a name
      
      target.framework_build_phase.add_file build_ident
      
      # Build Target Frameworks
      # 
      # 7165D44D146B4EA100DE2F0E /* Frameworks */ = {
      #   isa = PBXFrameworksBuildPhase;
      #   buildActionMask = 2147483647;
      #   files = (
      #     7165D455146B4EA100DE2F0E /* UIKit.framework in Frameworks */,
      #     7165D457146B4EA100DE2F0E /* Foundation.framework in Frameworks */,
      #     7165D459146B4EA100DE2F0E /* CoreGraphics.framework in Frameworks */,
      #     E245465314E0756B00082968 /* QuartzCore.framework in Frameworks */,
      #   );
      #   runOnlyForDeploymentPostprocessing = 0;
      # }; 
       
       
      
      
    end
    
  end
  
end