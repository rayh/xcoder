require_relative 'spec_helper'

describe Xcode::ProvisioningProfile do
  
  let(:adhoc) do
     path = "#{File.dirname(__FILE__)}/Provisioning/AdHoc.mobileprovision"
     Xcode::ProvisioningProfile.new(path) 
  end
  let(:appstore) do
     path = "#{File.dirname(__FILE__)}/Provisioning/AppStore.mobileprovision"
     Xcode::ProvisioningProfile.new(path) 
  end
  
  context "app store provisionig profile" do
    it "should read the uuid from the profile" do
      appstore.uuid.should=="81289CB8-4CC2-4A11-B3D6-82D8FA2BEC81"
    end
    it "should read the name from the profile" do
      appstore.name.should=="App Store"
    end
    it "should read identifiers from the profile" do 
      appstore.identifiers.count.should==1
      appstore.identifiers.first.should=="ZKVD5XDZZZ"
    end
    it "should know its an app store profile" do 
      appstore.appstore?.should==true
      appstore.devices.count.should==0
    end
    
  end
  
  context "ad hoc provisionig profile" do
    it "should read the uuid from the profile" do
      adhoc.uuid.should=="3FD4C48D-DD38-42E2-B535-C0F73198E52B"
    end
    it "should read the name from the profile" do
      adhoc.name.should=="AdHoc Distribution"
    end
    it "should read identifiers from the profile" do 
      adhoc.identifiers.count.should==1
      adhoc.identifiers.first.should=="ZKVD5XDZZZ"
    end
    it "should know its an ad hoc profile" do 
      adhoc.appstore?.should==false
      adhoc.devices.count.should==2
      adhoc.devices[0].should=="13cdd5c65c9c14f1e9a6f9885867d24fe77a2168"
      adhoc.devices[1].should=="b330b956d2b5a904a3da10224878d30ea96acaf4"
    end
  end
  
end