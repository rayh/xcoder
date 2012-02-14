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
      target.product_name = 'Specs'
      
      application_file = target.create_product_reference 'Specs'
      
      # Create the Specs group
    
      supporting_group = project.group('Specs/SupportingFiles')

      # Create the Source File and add it to the sources build phase
    
      main_source = supporting_group.create_file 'name' => 'main.m', 'path' => 'Specs/main.m'
    
      target.create_build_phase :sources do |source|
        source.add_build_file main_source
      end
      
      # Create the InfoPlist file and add it to the Resrouces build phase
      
      supporting_group.create_file 'name' => 'Specs-Info.plist', 'path' => 'Specs/Specs-Info.plist'
        
      infoplist_file = supporting_group.create_infoplist 'name' => 'InfoPlist.strings', 'path' => 'Specs'
      infoplist_file.create_file 'name' => 'en', 'path' => 'en.lproj/InfoPlist.strings'
      
      target.create_build_phase :resources do |resources|
        resources.add_build_file infoplist_file
      end
    
      prefix_file = supporting_group.create_file 'name' => 'Specs-Prefix.pch', 'path' => 'Specs/Specs-Prefix.pch'
      
      # Create the custom framework and add it to the frameworks build phase
      
      cedar_framework = target.project.frameworks_group.create_framework 'name' => 'Cedar-iPhone.framework', 'path' => 'Vendor/Frameworks/Cedar-iPhone.framework', 'sourceTree' => '<group>'
      
      target.create_build_phase :framework do |frameworks|
        frameworks.add_build_file cedar_framework
        frameworks.add_build_file project.file('Frameworks/UIKit.framework')
        frameworks.add_build_file project.file('Frameworks/Foundation.framework')
        frameworks.add_build_file project.file('Frameworks/CoreGraphics.framework')
      end
      
      # Add the necessary configurations
      
      target.create_configurations :debug, :release do |config|
        config.set 'GCC_PREFIX_HEADER', 'Specs/Specs-Prefix.pch'
        config.set 'INFOPLIST_FILE', 'Specs/Specs-Info.plist'
        config.set 'OTHER_LDFLAGS', '-ObjC -all_load -lstdc++'
        config.set 'FRAMEWORK_SEARCH_PATHS', [ "$(inherited)", "\"$(SRCROOT)/Vendor/Frameworks\"" ]
        config.save!
      end
    
    end
    
    project.save!
    
    expect { project.target('Specs').config('Debug').builder.build }.to_not raise_error
    
    project.save!
    
  end
  
end