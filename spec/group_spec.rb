require 'rspec'
require 'xcoder'

describe Xcode::Group do 

  let(:subject) { Xcode.project('TestProject') }
  
  describe "group" do
    
    context "when a group matches the name specified" do
      
      it "should return the group" do
        subject.groups.add_group('TestGroup')
        subject.groups.group('TestGroup').should_not be_nil
      end
      
    end
    
    context "when multiple groups match the name specified" do

      it "should return all the matching groups" do
        subject.groups.add_group('TestGroup')
        subject.groups.group('TestGroup').length.should == 2
      end

    end
    
    context "when a group does not match the name specified" do

      it "should return an e" do
        subject.groups.group('UnknownGroup').should be_empty
      end
      
    end
    
  end

  describe "#supergroup" do

    it "should return the owning group" do
      
      group = subject.groups.add_group('Superman')
      group.supergroup.identifier.should == subject.groups.identifier
      
    end

  end
  
  describe "#add_group" do
    
    it "should return the group" do
      subject.groups.add_group('TestGroup').should_not be_nil
    end

    context "when adding a group within a group" do
      
      it "should successfully create the subgroup" do
        subgroup = subject.groups.add_group('GroupWithSubGroup').add_group('Group MED')

        found_subgroup = subject.groups.group('GroupWithSubGroup').first.group('Group MED').first
        subgroup.should_not be_nil
        found_subgroup.should_not be_nil
        
        subgroup.identifier.should == found_subgroup.identifier
      end
      

    end

    context "when saving to file" do

      it "should save the group to the file" do
                
        # group = subject.groups.add_group 'TestGroup'
        # subject.save!
        # 
        # # TODO: load the ios project again and see the group in the root
        # 
        # file = subject.groups.add_file 'frank.txt'
        # file2 = subject.groups.add_file 'frank-webber.txt'
        # # p subject.registry.object file.identifier
        # 
        # p subject.groups.children
                
      end


    end

  end

end