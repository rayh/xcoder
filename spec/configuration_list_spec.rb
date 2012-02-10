require_relative 'spec_helper'

describe Xcode::ConfigurationList do
  
  let(:project) { Xcode.project 'TestProject' }
  let(:subject) { project.create_target('ConfigCreateTarget').build_configuration_list }
  
  describe "#configs" do
    it "should return all the configurations" do
      subject.build_configurations.count.should == 0
    end
  end
  
  describe "#create_config" do
    it "should add additional config" do
      subject.create_config('Debug2ElectricBoogaloo').should_not be_nil
    end
  end
  
  describe "#default_config" do
    context "when no default configuration has been specified" do
      it "should return a nil" do
        subject.default_config.should be_nil
      end
    end
    
    context "when a default configuration has been set" do
      it "it should return that configuration" do
        new_config = subject.create_config('Debug2ElectricBoogaloo')
        subject.set_default_config new_config.name
        subject.default_config_name.should == new_config.name
        subject.default_config.identifier.should == new_config.identifier
      end
    end

  end
  
end