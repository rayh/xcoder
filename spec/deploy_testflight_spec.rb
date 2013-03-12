require_relative 'spec_helper'
require 'ostruct'
require 'xcode/deploy/testflight'

describe Xcode::Deploy::Testflight do
  
  let(:testflight) do 
    builder = OpenStruct.new :ipa_path => 'ipa path', :dsym_zip_path => 'dsym path'
    Xcode::Deploy::Testflight.new(builder, {:api_token => 'api token', :team_token => 'team token' }) 
  end
  
  it "should be configured with api and team token" do
    testflight.api_token.should == 'api token'
    testflight.team_token.should == 'team token'
  end
  
  it "should call curl with correct bulld paths" do
    Xcode::Shell.should_receive(:execute) do |arg|
      arg.is_a? Xcode::Shell::Command
      arg.cmd.should == 'curl'
      arg.args.should include('-F file=@"ipa path"')
      arg.args.should include('-F dsym=@"dsym path"')
      arg.args.should include("-F api_token='api token'")
      arg.args.should include("-F team_token='team token'")
      
      ['{"response":"ok"}']
    end
    response = testflight.deploy
    response['response'].should == 'ok'
  end

end