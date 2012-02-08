require_relative 'spec_helper'

describe Xcode::Target do 
  
  let(:project) { Xcode.project 'TestProject' }
  let(:subject) { project.target 'TestProject' }

  let(:first_configuration_name) { "Debug" }
  let(:second_configuration_name) { "Release" }
  
  describe "#name" do
    
    let(:expected_name) { "TestProject" }
    
    it "should have the correct name" do
      subject.name == expected_name
    end
  end
  
  describe "#productName" do
    
    let(:expected_product_name) { "TestProject" }
    
    it "should have the correct productName" do
      subject.name == expected_product_name
    end
  end
  
  describe "#configs" do
    it "should return the correct number of configurations" do
      subject.configs.length.should == 2
    end
    
    it "should return the correct configuration" do
      subject.configs[0].name == first_configuration_name
      subject.configs[1].name == second_configuration_name
    end
  end
  
  describe "#config" do
    context "when a context exist with the specified name" do
      it "should return that configuration" do
        subject.config(first_configuration_name).should_not be_nil
      end

    end
    
    context "when no context exists with the specified name" do
      it "should raise an error" do
        expect { subject.config "UnknownConfig" }.to raise_error
      end

    end

  end
  
  describe "#build_phases" do
    it "should return all the build phases of the target" do
      subject.build_phases.count.should == 3
    end
  end
  
  describe "#framework_build_phase" do
    it "should return the correct build phase" do
      subject.framework_build_phase.should_not be_nil
    end
  end
  
  describe "#sources_build_phase" do
    it "should return the correct build phase" do
      subject.sources_build_phase.should_not be_nil
    end
  end
  
  describe "#resources_build_phase" do
    it "should return the correct build phase" do
      subject.resources_build_phase.should_not be_nil
    end
  end
  
  describe "#create_build_phases" do
    
    let(:subject) do
      
      project.create_target do |target|
        target.name = "CreateBuildPhasesTarget"
      end
      
    end
    
    context "when one phase is created" do
      
      it "should only create the one build phase" do
        build_phase = subject.create_build_phases :sources
        build_phase.count.should == 1
        subject.build_phases.count.should == 1
      end
      
      it "should create the build phase" do
        build_phase = subject.create_build_phases :sources
        subject.sources_build_phase.identifier.should == build_phase.first.identifier
      end
      
      it "should allow for the build phase to be customized" do
        subject.create_build_phases :sources do |phase|
          # Add files to the build phases
        end
      end
      
    end
    
    it "should create all the phases specified" do
      build_phases = subject.create_build_phases :resources, :framework, :sources
      subject.build_phases.count.should == 3
    end
    
    context "when the target is saved and reloaded" do

      let(:subject) do
        new_target = project.create_target do |target|
          target.name = "ReloadedBuildPhaseTarget"
        end
      end

      it "should save the build phases to the target if the target is saved" do

        subject.create_build_phases :resources, :framework
        subject.save!

        reloaded_target = project.target('ReloadedBuildPhaseTarget')
        reloaded_target.build_phases.count.should == 2
      end      

    end

    
  end
  
end