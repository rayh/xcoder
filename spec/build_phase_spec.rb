require_relative 'spec_helper'

describe Xcode::BuildPhase do
  
  let(:project) { Xcode.project('TestProject') }
  let(:target) {  project.target('TestProject') }
  
  describe "PBXSourcesBuildPhase" do
    
    let(:subject) { target.sources_build_phase }
    
    let(:first_build_file) { "main.m" }
    let(:second_build_file) { "AppDelegate.m" }
    
    describe "#files" do
      it "should return the correct number of build files" do
        subject.files.count.should == 2
      end
      
      it "should return BuildFiles with references to their files" do
        subject.files.each do |file| 
          file.file_ref.should be_kind_of Xcode::FileReference
        end
      end
    end
    
    describe "#file" do
      it "should return the build file specified from the file name" do
        subject.file('main.m').should_not be_nil
        subject.file('main.m').file_ref.path.should == 'main.m'
      end
    end
    
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
        source_file = project.groups.create_file 'NewFile.m'
        subject.add_build_file source_file
        subject.build_file('NewFile.m').should_not be_nil
      end
    end
    
    describe "#add_build_file_without_arc" do
      it "should add the specified file to the build phase with the correct parameters" do
        source_file = project.groups.create_file 'ArcLessSource.m'
        subject.add_build_file_without_arc source_file
        subject.build_file('ArcLessSource.m').should_not be_nil
        subject.file('ArcLessSource.m').settings.should == { 'COMPILER_FLAGS' => "-fno-objc-arc" }
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