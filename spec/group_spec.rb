require 'rspec'
require 'xcoder'

describe Xcode::Group do 

  let(:subject) { Xcode.project('TestProject').groups }
  
  describe "#groups" do
    context "when a group matches the name specified" do
      it "should return the group" do
        subject.add_group('TestGroup')
        subject.group('TestGroup').should_not be_nil
      end
    end
    
    context "when multiple groups match the name specified" do
      it "should return all the matching groups" do
        subject.add_group('TestGroup')
        subject.group('TestGroup').length.should == 2
      end
    end
    
    context "when a group does not match the name specified" do
      it "should return an e" do
        subject.group('UnknownGroup').should be_empty
      end
    end
  end
  
  describe "#supergroup" do
    it "should return the owning group" do
      group = subject.add_group('Superman')
      group.supergroup.identifier.should == subject.identifier
    end
  end
  
  describe "#add_group" do
    it "should return the group" do
      subject.add_group('TestGroup').should_not be_nil
    end

    context "when adding a group within a group" do
      it "should successfully create the subgroup" do
        subgroup = subject.add_group('GroupWithSubGroup').add_group('Group MED')

        found_subgroup = subject.group('GroupWithSubGroup').first.group('Group MED').first
        subgroup.should_not be_nil
        found_subgroup.should_not be_nil
        
        subgroup.identifier.should == found_subgroup.identifier
      end
    end

    context "when saving to file" do
      it "should save the group to the file" do
                
        # subject.groups.add_group 'TestGroup'
        # framework = subject.groups.add_framework 'QuartzCore'
        # 
        # # subject.target('TestProject').framework_build_phase.add_file framework
        # 
        # subject.targets.each do |target|
        #   
        #   target.framework_build_phase.add_build_file framework
        #   
        #   # target.configs.each do |config|
        #   #   config.set_other_linker_flags '-ObjC'
        #   # end
        # end
        # 
        # subject.save!
                
      end


    end

  end

end