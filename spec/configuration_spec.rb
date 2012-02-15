require_relative 'spec_helper'

describe Xcode::Configuration do 
  
  let(:target) { Xcode.project('TestProject').target('TestProject') }
  
  let(:subject) { target.config 'Debug' }
  
  describe "#name" do
    it "should parse the correct name" do
      subject.name.should == 'Debug'
    end
  end
  
  describe "#builder" do
    it "should return an instance of builder" do
      subject.builder.should_not be_nil
    end
  end
  
  
  describe "#supported_platforms" do
    it "should return the correct platforms" do
      # by default the test configuration defaults to the parent project configuration
      subject.supported_platforms.should == []
    end
  end
  
  describe "#supported_platforms=" do
    it "should correctly set the supported platforms" do
      subject.supported_platforms = "justthisplatform"
      subject.supported_platforms.should == [ "justthisplatform" ]
    end
  end
  
  describe "#product_name" do
    it "should return the correct product name" do
      subject.product_name.should == "TestProject"
    end
  end
  
  describe "#target" do
    it "should maintain a reference to the target that it belongs" do
      subject.target.should == target
    end
  end
  
  describe "#info_plist_location" do
    
    let(:expected_plist_location) { "TestProject/TestProject-Info.plist" }
    
    it "should return the location for the Info.plist file" do
      subject.info_plist_location.should == expected_plist_location
    end
  end
  
  describe "#build_settings" do
    it "should return a hash of build settings" do
      subject.build_settings.should_not
    end
  end
  
  describe "#set" do

    let(:settings) { subject.build_settings }
    
    it "should set a value in the build configuration" do
      subject.set 'KEY', 'VALUE'
      settings['KEY'].should == 'VALUE'
    end
    
    it "should override existing settings" do
      linker_flags = settings['OTHER_LDFLAGS']
      subject.set 'OTHER_LDFLAGS', '-NONE'
      settings['OTHER_LDFLAGS'].should_not == linker_flags
    end

  end
  
  describe "#get" do

    let(:settings) { subject.build_settings }
    
    it "should return the correct configuration value" do
      subject.get('OTHER_LDFLAGS').should == settings['OTHER_LDFLAGS']
    end

  end
  
end