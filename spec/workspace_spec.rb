require 'rspec'
require 'xcoder'

describe Xcode::Workspace do 
  it "should enumerate all workspaces in current directory" do 
    workspaces = Xcode.workspaces
    workspaces.size.should==1
    workspaces.first.name.should=="TestWorkspace"
    workspaces.first.projects.size.should==1
  end
  
  it "should fetch workspace by name" do 
    w = Xcode.workspace 'TestWorkspace'
    w.should_not be_nil
  end
  
  it "should fetch workspace by name with extension and path" do 
    w = Xcode.workspace "#{File.dirname(__FILE__)}/TestWorkspace.xcworkspace"
    w.should_not be_nil
  end
  
  it "should have many projects" do 
    w = Xcode.workspace "TestWorkspace"
    w.projects.size.should==1
    w.projects.first.name.should=="TestProject"
  end
  
  it "should get project by name" do 
    w = Xcode.workspace "TestWorkspace"
    p = w.project 'TestProject'
    p.name.should=="TestProject"
  end
end