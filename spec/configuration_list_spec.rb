require_relative 'spec_helper'

describe Xcode::ConfigurationList do
  
  let(:project) { Xcode.project 'TestProject' }
  let(:subject) { project.create_target('ConfigCreateTarget').configuration_list }
  
  describe "#configs" do
    
    it "should return all the configurations" do
      subject.buildConfigurations.count.should == 0
    end
  end
  
  describe "#create_config" do
    it "should add additional config" do
      subject.create_config('Debug2ElectricBoogaloo').should_not be_nil
    end
  end
  
  describe "#set_default_config" do
    it "should return the default configuration" do
      
    end
  end
  
end