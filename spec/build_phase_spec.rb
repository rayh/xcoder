require_relative 'spec_helper'

describe Xcode::BuildPhase do
  
  let(:project) { Xcode.project('TestProject') }
  let(:target) {  project.target('TestProject') }
  
  describe "PBXSourcesBuildPhase" do
    
    let(:subject) { target.sources_build_phase }
    
    let(:first_build_file) { "main.m" }
    let(:second_build_file) { "AppDelegate.m" }
    
    describe "#build_files" do
      it "should return the correct number of build files" do
        subject.build_files.count.should == 2
      end

      it "should return the correct build files " do
        subject.build_files.first.path.should == first_build_file
        subject.build_files.last.path.should == second_build_file
      end
    end
    
    describe "#build_file" do
      it "should return the correct file by name" do
        subject.build_file(first_build_file).should_not be_nil
        subject.build_file(first_build_file).path.should == subject.build_files.first.path
      end
    end
    
    describe "#add_build_file" do
      it "should add the specified file to the build phase" do
        source_file = project.groups.add_file 'NewFile.m'
        subject.add_build_file source_file
        subject.build_file('NewFile.m').should_not be_nil
      end
    end
  end
  
  
  describe "PBXFrameworksBuildPhase" do
    
    let(:subject) { target.framework_build_phase }
    
    let(:first_build_file) { "System/Library/Frameworks/UIKit.framework" }
    let(:second_build_file) { "System/Library/Frameworks/Foundation.framework" }
    let(:third_build_file) { "System/Library/Frameworks/CoreGraphics.framework" }
    
    describe "#build_files" do
      it "should return the correct number of build files" do
        subject.build_files.count.should == 3
      end

      it "should return the correct build files " do
        subject.build_files[0].path.should == first_build_file
        subject.build_files[1].path.should == second_build_file
        subject.build_files[2].path.should == third_build_file
      end

    end
    
  end
  
  
  describe "PBXResourcesBuildPhase" do
    
    let(:subject) { target.resources_build_phase }
    
    let(:first_build_file) { "InfoPlist.strings" }
    
    describe "#build_files" do
      it "should return the correct number of build files" do
        subject.build_files.count.should == 1
      end

      it "should return the correct build files " do
        subject.build_files.first.name.should == first_build_file
      end

    end
    
  end
  
end