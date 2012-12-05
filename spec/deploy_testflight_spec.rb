require_relative 'spec_helper'

describe Xcode::Deploy::Testflight do
  
  let(:testflight) { Xcode::Deploy::Testflight.new 'api token', 'team token' }
  
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
    response = testflight.upload('ipa path', 'dsym path')
    response['response'].should == 'ok'
  end

end