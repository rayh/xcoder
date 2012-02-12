require_relative '../spec_helper'

describe "Reachability", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should update a project with a working installation of Reachability" do
    
    # Copy the files necessary for the project to the correct destination
    
    FileUtils.cp_r "examples/Reachability/Vendor", "spec/TestProject"
    
    # Create or traverse to the group to install the source files
    
    reach_group = project.group('Vendor/Reachability')
    
    # Add the source and header file to the project
    
    source_files = [ { 'name' => 'Reachability.m', 'path' => 'Vendor/Reachability/Reachability.m' },
                     { 'name' => 'Reachability.h', 'path' => 'Vendor/Reachability/Reachability.h' } ]
    
    
    source_files.each do |source|
      reach_group.create_file(source) if reach_group.file(source['name']).empty?
    end
    
    source_file = reach_group.file('Reachability.m').first
    
    # Select the main target of the project and add the source file to the build phase.
    
    source_build_phase = project.target('TestProject').sources_build_phase
    source_build_phase.add_build_file(source_file) unless source_build_phase.build_file(source_file.name)

    cfnetwork_framework = project.frameworks_group.create_system_framework 'CFNetwork'

    framework_phase = project.target('TestProject').framework_build_phase
    framework_phase.add_build_file(cfnetwork_framework) unless framework_phase.build_file(cfnetwork_framework.name)
    
    project.save!
    
  end
  
end