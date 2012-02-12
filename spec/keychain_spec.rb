require 'rspec'
require 'xcoder'

describe Xcode::Keychain do 
  it "should create a keychain" do 
    kc = Xcode::Keychain.temp_keychain('Test.keychain') do |kc|
      puts kc.path
      File.exists?(kc.path).should==true
    end
    File.exists?(Xcode::Keychain.new('Test.keychain').path).should==false
  end
  
  it "should import a certificate" do 
    Xcode::Keychain.temp_keychain('Test2.keychain') do |kc|
      kc.import "#{File.dirname(__FILE__)}/Provisioning/TestUser.p12", 'testpassword'
      kc.identities.size.should==1
      kc.identities[0].should=="Test User"
    end
  end
  
  it "should fetch the login keychain" do
    kc = Xcode::Keychain.login_keychain
    File.exists?(kc.path).should==true
  end
end