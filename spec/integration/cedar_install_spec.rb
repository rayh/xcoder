require_relative '../spec_helper'

describe "Cedar", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should update a project with a working installation of Cedar" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/Cedar/Vendor", "spec/TestProject"
    FileUtils.cp_r "examples/Cedar/Specs", "spec/TestProject"
    
    #
    # The following block of code will generate the target with all the neccessary
    # parameters and properties to get a full working 'Cedar' spec to build.
    # 
    
    project.create_target 'Specs' do |target|
      
      target.name = 'Specs'
      target.productName = 'Specs'
      
      # @todo create the following files within the project file
    
      # E21EB9D614E357CF0058122A /* Specs.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Specs.app; sourceTree = BUILT_PRODUCTS_DIR; };
      # Adding an application needs to set the productReference in the target
      # productReference = E21EB9D614E357CF0058122A /* Specs.app */;
    
      application_file = target.create_product_reference 'Specs'
      # target.properties['productReference'] = application_file.identifier
      
      # Create the Specs group
    
      specs_group = project.groups.create_group('Specs')
      supporting_group = specs_group.create_group('Supporting Files')
    
    
      # E21EB9E114E357CF0058122A /* main.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = main.m; sourceTree = "<group>"; };
      main_source = supporting_group.create_file 'name' => 'main.m', 'path' => 'Specs/main.m'
    
      target.create_build_phase :sources do |source|
        source.add_build_file main_source
      end
    
      # E21EB9DD14E357CF0058122A /* Specs-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Specs-Info.plist"; sourceTree = "<group>"; };
    
      supporting_group.create_file 'name' => 'Specs-Info.plist', 'path' => 'Specs/Specs-Info.plist'
    
      # E2B8B9F214E395B400D08897 /* InfoPlist.strings */ = {
      #   isa = PBXVariantGroup;
      #   children = (
      #     E2B8B9F314E395B400D08897 /* en */,
      #   );
      #   name = InfoPlist.strings;
      #   path = Specs/en.lproj;
      #   sourceTree = "<group>";
      # };
          
      infoplist_file = supporting_group.create_infoplist 'name' => 'InfoPlist.strings', 'path' => 'Specs'
      infoplist_file.create_file 'name' => 'en', 'path' => 'en.lproj/InfoPlist.strings'
      
      # E21EB9DF14E357CF0058122A /* en */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = en.lproj/InfoPlist.strings; sourceTree = "<group>"; };
      # infofile = supporting_group.create_file 'name' => 'en', 'path' => 'en.lproj/InfoPlist.strings'
    
      target.create_build_phase :resources do |resources|
        resources.add_build_file infoplist_file
      end
    
      # E21EB9E314E357CF0058122A /* Specs-Prefix.pch */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = "Specs-Prefix.pch"; sourceTree = "<group>"; };
      prefix_file = supporting_group.create_file 'name' => 'Specs-Prefix.pch', 'path' => 'Specs/Specs-Prefix.pch'
    
      # E21EB9D814E357CF0058122A /* UIKit.framework in Frameworks */,
      # 7165D454146B4EA100DE2F0E /* UIKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = UIKit.framework; path = System/Library/Frameworks/UIKit.framework; sourceTree = SDKROOT; };
      # E21EB9D914E357CF0058122A /* Foundation.framework in Frameworks */,
      # E21EB9DA14E357CF0058122A /* CoreGraphics.framework in Frameworks */,
    
      # E21EB9EE14E359840058122A /* Cedar-iPhone.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = "Cedar-iPhone.framework"; path = "Vendor/Frameworks/Cedar-iPhone.framework"; sourceTree = "<group>"; };
      cedar_framework = target.project.frameworks_group.create_framework 'name' => 'Cedar-iPhone.framework', 'path' => 'Vendor/Frameworks/Cedar-iPhone.framework', 'sourceTree' => '<group>'
      
      target.create_build_phase :framework do |frameworks|
        frameworks.add_build_file cedar_framework
        frameworks.add_build_file target.project.frameworks_group.file('UIKit.framework')
        frameworks.add_build_file target.project.frameworks_group.file('Foundation.framework')
        frameworks.add_build_file target.project.frameworks_group.file('CoreGraphics.framework')
      end
      
      target.create_configuration 'Debug' do |config|
        config.set 'GCC_PREFIX_HEADER', 'Specs/Specs-Prefix.pch'
        config.set 'INFOPLIST_FILE', 'Specs/Specs-Info.plist'
        config.set 'OTHER_LDFLAGS', '-ObjC -all_load -lstdc++'
        config.set 'FRAMEWORK_SEARCH_PATHS', [ "$(inherited)", "\"$(SRCROOT)/Vendor/Frameworks\"" ]
        config.save!
      end
      
      target.create_configuration 'Release' do |config|
        config.set 'GCC_PREFIX_HEADER', 'Specs/Specs-Prefix.pch'
        config.set 'INFOPLIST_FILE', 'Specs/Specs-Info.plist'
        config.set 'OTHER_LDFLAGS', '-ObjC -all_load -lstdc++'
        config.set 'FRAMEWORK_SEARCH_PATHS', [ "$(inherited)", "\"$(SRCROOT)/Vendor/Frameworks\"" ]
        config.save!
      end
    
    end
    
    project.save!
    
    expect { project.target('Specs').config('Debug').builder.build }.to_not raise_error
    
    project.remove_target('Specs')
    
    project.save!
    
  end
  
end