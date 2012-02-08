require_relative 'spec_helper'

describe Xcode::Project do 

  let(:project) { Xcode.project 'TestProject' }


  describe "Targets" do
    
    let(:expected_first_target) { "TestProject" }
    let(:expected_second_target) { "TestProjectTests" }
    
    describe "#targets" do

      let(:subject) { project.targets }

      it "should give the correct number of targets" do
        subject.size.should == 2
      end
      
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

      context "when creating an IOS target" do

        it "should create the target" do
          
          # project.create_target :ios do |target|
          #   
          #   target.name = 'newtarget'
          #   target.productName = 'newProductName'
          #   
          #   target.properties['name'].should == 'newtarget'
          #   target.properties['productName'].should == 'newProductName'
          #   
          #   target.create_build_phases :resources, :sources, :frameworks each do |phase|
          #     # Custom build phase creation (i.e. set files)
          #   end
          #   
          #   # TODO: auto-generates a configuration list or appends to the configuration list
          #   target.create_build_configurations :debug, :release do |config|
          #     # Custom configuration settings
          #   end
          #   
          #   target.default_configuration = :release
          #   
          #   target.add_product do |product|
          #     # Custom product settings
          #     # 
          #     # Defaults to adding the product to the 'Products' group
          #     # 
          #     # product.name
          #   end
          #   
          # end
          # 
          # project.save!
          
        end

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
  
end