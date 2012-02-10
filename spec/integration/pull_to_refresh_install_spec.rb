require_relative '../spec_helper'
require 'fileutils'

describe "EGORefreshTableHeaderView", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should install without error" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/EGORefreshTableHeaderView/Vendor", "spec/TestProject"
    
    # Create or traverse to the group to install the source files
    
    ptr_group = project.group('Vendor/EGORefreshTableHeaderView')
    
    # Add the source and header file to the project
    # @todo this currently will add the files multiple times based on the application 
    #   execution. This should be addressed to check before adding.
    
    ptr_source = ptr_group.create_file 'name' => 'EGORefreshTableHeaderView.m', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.m'
    ptr_header = ptr_group.create_file 'name' => 'EGORefreshTableHeaderView.h', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.h'
    
    # Select the main target of the project and add the source file to the build
    # phase.
    # 
    # @todo this currently will add the files multiple times based on the application 
    #   execution. This should be addressed to check before adding.
    
    install_target = project.target('TestProject')
    install_target.sources_build_phase.add_build_file ptr_source
    
    project.save!
  end

end