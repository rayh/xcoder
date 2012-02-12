require_relative '../spec_helper'

describe "Reachability", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should update a project with a working installation of Reachability" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/Reachability/Vendor", "spec/TestProject"
    
    
    # Add the source and header file to the project
    
    source_files = [ { 'name' => 'Reachability.m', 'path' => 'Vendor/Reachability/Reachability.m' },
                     { 'name' => 'Reachability.h', 'path' => 'Vendor/Reachability/Reachability.h' } ]
    

     # Create or traverse to the group to install the source files
     project.group('Vendor/Reachability') do
       source_files.each do {|source| create_file source }
     end

    source_file = project.file('Vendor/Reachability/Reachability.m')
    
    # Select the main target of the project and add the source file to the build phase.
    
    project.target('TestProject').sources_build_phase do
      add_build_file source_file
    end
    
    cfnetwork_framework = project.frameworks_group.create_system_framework 'CFNetwork'

    project.target('TestProject').framework_build_phase do
      add_build_file cfnetwork_framework
    end 
    
    project.save!
    
  end
  
end