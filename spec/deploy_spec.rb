require_relative 'spec_helper'
require 'ostruct'
require 'xcode/deploy/testflight'
require 'xcode/deploy/web_assets'
require 'xcode/deploy/ftp'
require 'xcode/deploy/ssh'

describe Xcode::Deploy do

  let :builder do
    OpenStruct.new(
      :ipa_path => 'ipa path', 
      :dsym_zip_path => 'dsym path',
      :bundle_version => '1.0',
      :bundle_identifier => 'test.bunlde.identifier'
    )
  end

  describe Xcode::Deploy::WebAssets do 
    it "should generate the assets" do
      Xcode::Deploy::WebAssets.generate builder, 'http://example.com/base-url' do |dir|
        File.exists?("#{dir}/index.html").should == true
        File.exists?("#{dir}/manifest.plist").should == true

        # TODO: more tests
      end
    end
  end

  describe Xcode::Deploy::Ftp do 
    # TODO: tests!
  end

  describe Xcode::Deploy::Ssh do 
    # TODO: tests!
  end
  
  describe Xcode::Deploy::Testflight do

    let(:testflight) do 
      Xcode::Deploy::Testflight.new(builder, {:api_token => 'api token', :team_token => 'team token' }) 
    end
    
    it "should be configured with api and team token" do
      testflight.api_token.should == 'api token'
      testflight.team_token.should == 'team token'
    end
    
    it "should call curl with correct bulld paths" do
      PTY.stub(:spawn).with do |cmd, &block|
        cmd.should =~/^curl/
        cmd.should =~/-F file=@"ipa path"/
        cmd.should =~/-F dsym=@"dsym path"/
        cmd.should =~/-F api_token='api token'/
        cmd.should =~/-F team_token='team token'/                
      end

      testflight.deploy
      # response['response'].should == 'ok'
    end
  end

end