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
  
end