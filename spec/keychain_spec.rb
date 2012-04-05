require 'rspec'
require 'xcoder'

describe Xcode::Keychain do 
  it "should create a keychain" do 
    path = nil
    kc = Xcode::Keychain.temp do |kc|
      path = kc.path
      File.exists?(kc.path).should==true
    end
    File.exists?(path).should==false
  end
  
  it "should import a certificate" do 
    Xcode::Keychain.temp do |kc|
      kc.import "#{File.dirname(__FILE__)}/Provisioning/TestUser.p12", 'testpassword'
      kc.identities.size.should==1
      kc.identities[0].should=="Test User"
    end
  end
  
  it "should open an existing keychain" do
    kc = Xcode::Keychain.new("#{File.dirname(__FILE__)}/Provisioning/Test.keychain")
    kc.unlock 'testpassword'
    kc.identities.size.should==1
    kc.identities[0].should=="Test User"
  end
  
  # FIXME: Need to surpress GUI dialog prompting to unlock keychain
  # it "should lock the keychain" do 
  #     kc = Xcode::Keychain.temp
  #     kc.lock
  #     kc.import "#{File.dirname(__FILE__)}/Provisioning/TestUser.p12", 'testpassword'
  #     kc.identities.size.should==0
  #   end
  
  it "should fetch the login keychain" do
    kc = Xcode::Keychain.login
    File.exists?(kc.path).should==true
  end
  
  it "should read the current keychain search path" do
    Xcode::Keychain.keychains[0].path.should=~/login.keychain/
  end
  
  it "should update the keychain search path" do
    keychains = Xcode::Keychain.keychains
    test_keychain = Xcode::Keychain.new("#{File.dirname(__FILE__)}/Provisioning/Test.keychain")
    begin 
      Xcode::Keychain.keychains = [test_keychain] + keychains
      `security list-keychains`.include?(test_keychain.path).should be_true
    ensure
      Xcode::Keychain.keychains = keychains
    end
  end
end