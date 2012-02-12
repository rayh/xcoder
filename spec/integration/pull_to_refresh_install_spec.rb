require_relative '../spec_helper'

describe "EGORefreshTableHeaderView", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should install without error" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/EGORefreshTableHeaderView/Vendor", "spec/TestProject"
    
    # Add the source and header file to the project
    
    source_files = [ { 'name' => 'EGORefreshTableHeaderView.m', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.m' },
                     { 'name' => 'EGORefreshTableHeaderView.h', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.h' } ]

    # Create or traverse to the group to install the source files

    project.group('Vendor/EGORefreshTableHeaderView') do
      source_files.each {|source| create_file source }
    end

    ptr_source = project.file('Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.m')
    
    # Select the main target of the project and add the source file to the build
    # phase.
    
    project.target('TestProject').sources_build_phase do
      add_build_file ptr_source
    end
    
    project.save!
  end

end