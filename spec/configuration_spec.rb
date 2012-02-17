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
  
  let(:string_properties) do
    [ :product_name, 
      :prefix_header,
      :info_plist_location,
      :wrapper_extension,
      :sdkroot,
      :c_language_standard,
      :gcc_version,
      :code_sign_identity,
      :iphoneos_deployment_target ]
    end

  describe "String Properties" do
    
    it "should be able to correctly get the property" do
      
      string_properties.each do |property|
        subject.send(property).should be_kind_of(String), "#{property} failed to return a String"
      end
      
    end
    
    it "should be able to correctly set the property" do
      
      string_properties.each do |property|
        subject.send("#{property}=","new value")
        subject.send(property).should eq("new value"), "#{property} failed to be set correctly"
      end
      
    end
    
    it "should be able to append to the property" do
      
      string_properties.each do |property|
        subject.send("#{property}=","new value")
        subject.send("append_to_#{property}"," there")
        subject.send(property).should eq("new value there"), "#{property} failed to be set correctly"
      end
      
    end
    
  end

  let(:boolean_properties) do
    [ :precompile_prefix_headers,
      :always_search_user_paths,
      :warn_about_missing_prototypes,
      :warn_about_return_type,
      :validate_product,
      :copy_phase_strip ]
  end
  
  describe "Boolean Properties" do

    it "should be able to set to false with NO" do
      
      boolean_properties.each do |property|
        subject.send("#{property}=","NO")
        subject.send(property).should be_false, "#{property} failed to be set correctly to false"
      end
      
    end

    it "should be able to set to false with false" do
      
      boolean_properties.each do |property|
        subject.send("#{property}=",false)
        subject.send(property).should be_false, "#{property} failed to be set correctly to false"
      end
      
    end
    
    it "should be able to true with YES" do

      boolean_properties.each do |property|
        subject.send("#{property}=","YES")
        subject.send(property).should be_true, "#{property} failed to be set correctly to true"
      end
      
    end
    
    it "should be able to set set to true with true" do
      
      boolean_properties.each do |property|
        subject.send("#{property}=",true)
        subject.send(property).should be_true, "#{property} failed to be set correctly to true"
      end
      
    end
  end
  
  let(:space_delimited_string_properties) do
    [ :architectures,
      :supported_platforms ]
  end
  
  describe "Space Delimited String Properties" do

    it "should be able to correctly get the property" do
      
      space_delimited_string_properties.each do |property|
        subject.send(property).should be_kind_of(Array), "#{property} failed to return an Array"
      end
      
    end
    
    it "should be able to correctly set the property with a string with spaces" do
      
      space_delimited_string_properties.each do |property|
        subject.send("#{property}=","new value")
        subject.send(property).should eq([ "new", "value" ]), "#{property} failed to be set correctly"
      end
      
    end
    
    it "should be able to correctly set the property with an array" do
      
      space_delimited_string_properties.each do |property|
        subject.send("#{property}=",["more", "value"])
        subject.send(property).should eq([ "more", "value" ]), "#{property} failed to be set correctly"
      end
      
    end
    
    it "should be able to append to the property" do
      
      space_delimited_string_properties.each do |property|
        subject.send("#{property}=",["more", "value"])
        subject.send("append_to_#{property}","there")
        subject.send(property).should eq([ "more", "value", "there" ]), "#{property} failed to be set correctly"
      end
      
    end
    
  end
  
  let(:targeted_device_family_properties) { [ :targeted_device_family ] }
  
  describe "Targeted Device Family Properties" do

    it "should be able to correctly get the property" do
      
      targeted_device_family_properties.each do |property|
        subject.send(property).should == [ ]
      end
      
    end
    
    it "should be able to correctly set the property with device names" do
      
      targeted_device_family_properties.each do |property|
        subject.send("#{property}=",[ 'IPHONE', :ipad ])
        subject.get("TARGETED_DEVICE_FAMILY").should == "1,2"
        subject.send(property).should == [ :iphone, :ipad ]
      end
      
    end
    
    it "should be able to append to the property" do
      
      targeted_device_family_properties.each do |property|
        subject.send("#{property}=",'IPHONE')
        subject.send("append_to_#{property}","iPad")
        subject.send(property).should == [ :iphone, :ipad ]
      end
      
    end
    
  end
  
  let(:array_properties) do
    [ :other_c_flags ]
  end
  
  describe "Array Properties" do
    it "should be able to correctly get the property" do
      array_properties.each do |property|
        subject.send(property).should be_kind_of(Array), "#{property} failed to return an Array"
      end
    end
    
    it "should be able to correctly set the property" do
      array_properties.each do |property|
        subject.send("#{property}=","PARAMETER=1")
        subject.send(property).should eq(["PARAMETER=1"]), "The property #{property} failed to set correctly"
      end
    end
  end
  
  
  let(:all_properties) do
    string_properties + 
    boolean_properties + 
    space_delimited_string_properties +
    targeted_device_family_properties + 
    array_properties
  end
  
  describe "Property Environment Names" do
    it "should have all property environment names available" do
      all_properties.each do |property|
        subject.send("env_#{property}").should_not be_nil, "The property #{property} does not have an env_#{property} method defined"
      end
    end
  end
  
  describe "Raw Getter and Setter" do
    it "should have a raw getter method" do
      all_properties.each do |property|
        subject.should respond_to("raw_#{property}"), "The property #{property} does not have a raw_#{property} getter method defined"
      end
    end
    
    it "should have a raw setter method" do
      all_properties.each do |property|
        subject.should respond_to("raw_#{property}="), "The property #{property} does not have a raw_#{property} setter method defined"
      end
    end
  end
  
end