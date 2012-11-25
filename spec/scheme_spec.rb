require_relative 'spec_helper'

describe Xcode::ProjectScheme do 
  let :project do
    Xcode.project 'TestProject'
  end
  
  let :workspace do
    Xcode.workspace 'TestWorkspace'
  end
  
  context "Project schemes" do
    it "should parse project schemes" do 
      scheme = project.scheme('TestProject')
      scheme.name.should=="TestProject"
      scheme.launch.target.name.should == 'TestProject'
      scheme.launch.target.project.name.should == 'TestProject'
    end
    
    it "should return an array of schemes" do
      project.schemes.size.should == 6
    end
  
    it "should complain that no such scheme exists" do
      lambda do 
        project.scheme('BadScheme')
      end.should raise_error
    end
  end
  
  context "Workspace schemes" do
    it "should complain that no such scheme exists" do
      lambda do 
        workspace.scheme('BadScheme')
      end.should raise_error
    end
  
    it "should return an array of schemes" do
      workspace.schemes.size.should == 1
    end
  
    it "should parse workspace schemes" do 
      scheme = workspace.scheme('WorkspaceScheme')
      scheme.name.should=="WorkspaceScheme"
      scheme.launch.target.name.should == 'TestProject'
      scheme.launch.target.project.name.should == 'TestProject'
    end
  end
  

end