require_relative 'spec_helper'

describe Xcode::Group do

  let(:project) { Xcode.project('TestProject') }
  let(:subject) { project.groups }

  describe "#groups" do
    context "when a group matches the name specified" do
      it "should return the group" do
        subject.create_group('TestGroup')
        subject.group('TestGroup').should_not be_nil
      end
    end

    context "when multiple groups match the name specified" do
      it "should return all the matching groups" do
        subject.create_group('TestGroup')
        subject.group('TestGroup').length.should == 2
      end
    end

    context "when a group does not match the name specified" do
      it "should return an empty array" do
        subject.group('UnknownGroup').should be_empty
      end
    end
  end

  describe "#supergroup" do
    it "should return the owning group" do
      group = subject.create_group('Superman')
      group.supergroup.identifier.should == subject.identifier
    end
  end

  describe "#create_group" do
    it "should return the group" do
      subject.create_group('TestGroup').should_not be_nil
    end

    context "when adding a group within a group" do
      it "should successfully create the subgroup" do
        subgroup = subject.create_group('GroupWithSubGroup').create_group('Group MED')

        found_subgroup = subject.group('GroupWithSubGroup').first.group('Group MED').first
        subgroup.should_not be_nil
        found_subgroup.should_not be_nil

        subgroup.identifier.should == found_subgroup.identifier
      end
    end
  end

  describe "#remove!" do

    let!(:subject) { project.group('created/groups/to') }
    let!(:group_losing_a_child) { project.group('created/groups') }
    let!(:remove_grandchild) { project.group('created/groups/to/here') }

    it "should remove the group and all the children" do
      subject.supergroup.remove!
      group_losing_a_child.groups.should be_empty
    end

  end

  describe "Files" do
    let(:subject) { project.groups.group('TestProject').first }

    describe "#files" do
      it "should return the correct number of files within the group" do
        subject.files.count.should == 2
      end
    end

    describe "#file" do
      it "should return the files that match" do
        subject.file('AppDelegate.m').should_not be_empty
      end
    end

    describe "#create_file" do

      let(:new_file_params) { {'name' => 'NewFile.m', 'path' => 'NewFile.m'} }

      before(:each) do
        subject.create_file new_file_params
      end

      it "should create the files within the group" do
        subject.file(new_file_params['name']).should_not be_empty
      end

      it "should not duplicate the file within the group" do
        subject.create_file new_file_params
        subject.file(new_file_params['name']).count.should == 1
      end
    end

    describe "#create_system_framework" do

      let(:framework_name) { 'CFNetwork' }
      let(:full_framework_name) { 'CFNetwork.framework' }

      before(:each) do
        subject.create_system_framework framework_name
      end

      it "should create the framework within the group" do
        subject.file(full_framework_name).should_not be_nil
      end

      it "should not create the framework again if it exists" do
        expect(subject.exists?(full_framework_name)).to be_truthy
        subject.create_system_framework framework_name
        subject.file(full_framework_name).count.should == 1
      end

    end

    describe "#create_system_library" do

      let(:library_name) { 'libz.dylib' }

      it "should create the system library within the group" do
        subject.create_system_library library_name
      end

      it "should create a system library with the correct path" do
        subject.create_system_library(library_name).path.should == "usr/lib/libz.dylib"
      end

      it "should not create a system library twice" do
        subject.create_system_library library_name
        subject.create_system_library library_name
        subject.file(library_name).count.should == 1
      end

    end

  end

end