require 'rspec'
require 'xcoder'

describe Xcode::Group do 

  let(:subject) { Xcode.project('TestProject').groups }
  
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
  
  describe "#add_group" do
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
  
  describe "#files" do
    it "should return the correct number of files within the group" do
      subject.group('TestProject').first.files.count.should == 2
    end
  end
end