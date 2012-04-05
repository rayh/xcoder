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
end

describe Xcode::Keychains do
  it "should read the current keychain search path" do
    Xcode::Keychains.search_path[0].path.should=~/login.keychain/
  end
  
  it "should update the keychain search path" do
    keychains = Xcode::Keychains.search_path
    test_keychain = Xcode::Keychain.new("#{File.dirname(__FILE__)}/Provisioning/Test.keychain")
    begin 
      Xcode::Keychains.search_path = [test_keychain] + keychains
      `security list-keychains`.include?(test_keychain.path).should be_true
    ensure
      Xcode::Keychains.search_path = keychains
    end
  end
  
  it "should add the keychain to the search path and then remove it" do
    test_keychain = Xcode::Keychain.new("#{File.dirname(__FILE__)}/Provisioning/Test.keychain")
    Xcode::Keychains.with_keychain_in_search_path test_keychain do  
      `security list-keychains`.include?(test_keychain.path).should be_true
    end
    
    `security list-keychains`.include?(test_keychain.path).should be_false
  end
end