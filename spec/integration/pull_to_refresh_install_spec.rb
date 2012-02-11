require_relative '../spec_helper'

describe "EGORefreshTableHeaderView", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should install without error" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/EGORefreshTableHeaderView/Vendor", "spec/TestProject"
    
    # Create or traverse to the group to install the source files
    
    ptr_group = project.group('Vendor/EGORefreshTableHeaderView')
    
    # Add the source and header file to the project
    
    source_files = [ { 'name' => 'EGORefreshTableHeaderView.m', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.m' },
                     { 'name' => 'EGORefreshTableHeaderView.h', 'path' => 'Vendor/EGORefreshTableHeaderView/EGORefreshTableHeaderView.h' } ]
    
    source_files.each do |source|
      ptr_group.create_file(source) if ptr_group.file(source['name']).empty?
    end
    
    ptr_source = ptr_group.file('EGORefreshTableHeaderView.m').first
    
    # Select the main target of the project and add the source file to the build
    # phase.
    
    source_build_phase = project.target('TestProject').sources_build_phase
    
    source_build_phase.add_build_file(ptr_source) unless source_build_phase.build_file(ptr_source.name)
    
    project.save!
  end

end