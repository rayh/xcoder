require_relative 'spec_helper'

describe Xcode::Project do 

  let(:project) { Xcode.project 'TestProject' }

  describe "Targets" do
    
    let(:expected_first_target) { "TestProject" }
    let(:expected_second_target) { "TestProjectTests" }
    
    describe "#targets" do

      let(:subject) { project.targets }

      it "should return the correct targets" do
        subject[0].name.should == expected_first_target
        subject[1].name.should == expected_second_target
      end

    end

    describe "#target" do
      context "when the target exists" do

        let(:subject) { project.target expected_first_target }

        it "should return the specified target" do
          subject.should_not be_nil
        end

      end
      
      context "when the target does not exist" do

        let(:subject) { project.target 'UnknownTarget' }
        
        it "should raise an error" do
          expect { subject }.to raise_error
        end

      end

    end
  
    describe "#create_target" do
      
      let(:subject) { project.create_target('SuperNewTestTarget') }
      
      it "should generate a target with the name specified" do
        subject.name.should == 'SuperNewTestTarget'
      end
      
      it "should be available in the list of project targets" do
        project.target('SuperNewTestTarget').should_not be_nil
      end
      
      it "should generate a target that knows the project" do
        subject.project.should == project
      end
    end
    
    describe "#remove_target" do
      
      let(:subject) { project.create_target('SoonToBeRetiredTarget') }
      
      it "should remove the target created" do
        project.remove_target(subject.name)
        project.targets.find {|target| target.name == subject.name }.should be_nil
        
      end

    end
    
  end
  
  describe "Schemes" do
    
    let(:expected_scheme) { "TestProject" }
    
    describe "#schemes" do
      
      let(:subject) { project.schemes }
      
      let(:shared_scheme_count) { Dir["spec/TestProject/TestProject.xcodeproj/xcshareddata/xcschemes/*.xcscheme"].count }
      let(:user_scheme_count) { Dir["spec/TestProject/TestProject.xcodeproj/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"].count }
      
      it "should find all global schemes and schemes unique to the user" do
        subject.size.should == shared_scheme_count + user_scheme_count
      end
      
      it "should return the correct schemes" do
        subject.first.name.should == expected_scheme
      end
     
    end
    
    describe "#scheme" do
      context "when the scheme exists" do

        let(:subject) { project.scheme expected_scheme }

        it "should return the specified scheme" do
          subject.should_not be_nil
        end

      end
      
      context "when the scheme does not exist" do

        let(:subject) { project.scheme 'UnknownScheme' }

        it "should raise an error" do
          expect { subject }.to raise_error
        end

      end

    end
    
  end
  
  describe "#group" do
    it "should find or create the entire path specified" do
      group = project.group('fe/fi/fo/fum')
      group.name.should == "fum"
      group.supergroup.name.should == "fo"
    end
  end
  
  describe "#products_group" do
    it "should find the 'Products' group" do
      project.products_group.should_not be_nil
    end
  end
  
  describe "#frameworks_group" do
    it "should find the 'Frameworks' group" do
      project.products_group.should_not be_nil
    end
  end
  
  describe "#to_xcplist" do
    it "should respond to this method" do
      project.should respond_to :to_xcplist
    end
  end
  
  describe "#object_version" do
    it "should return the correct version" do
      project.object_version.should == "46"
    end
  end
  
  describe "#archive_version" do
    it "should return the correct version" do
      project.archive_version.should == "1"
    end
  end
  
end