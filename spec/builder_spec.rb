require_relative 'spec_helper'

RSpec.configure do |config|
  config.mock_with :rspec
end

describe Xcode::Builder do

  context "when using a builder built from a configuration" do

    let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }

    let(:subject) { configuration.builder }

    describe "#build" do

      let(:default_build_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk #{configuration.target.project.sdk}"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd
      end

      let(:macosx_build_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk macosx10.7"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd
      end

      it "should build the project with the default parameters" do
        PTY.stub(:spawn).and_return(default_build_parameters.to_s)
        subject.build
      end

      it "should allow the override of the sdk" do
        PTY.stub(:spawn).and_return(macosx_build_parameters.to_s)
        subject.build :sdk => 'macosx10.7'
      end

    end

    describe "#testflight" do

      # let(:testflight_parameters) do
      #   ['curl',
      #   "--proxy http://proxyhost:8080",
      #   "-X POST http://testflightapp.com/api/builds.json",
      #   "-F file=@\"#{subject.ipa_path}\"",
      #   "-F dsym=@\"#{subject.dsym_zip_path}\"",
      #   "-F api_token='api_token'",
      #   "-F team_token='team_token'",
      #   "-F notes=\"some notes\"",
      #   "-F notify=True",
      #   "-F distribution_lists='List1,List2'"]
      # end

      it "should upload ipa and dsym to testflight" do
        subject.build.package
        testflight = nil
        result = subject.deploy(:testflight,
          :api_token => "api_token",
          :team_token => "team_token",
          # :proxy => "http://proxyhost:8080",
          :notes => "some notes",
          :lists => ["List1", "List2"]) do |tf|
            testflight = tf
            tf.should_receive(:deploy).and_return('result')
        end
        result.should == 'result'
        testflight.should_not==nil
        testflight.api_token.should=="api_token"
        testflight.team_token.should=="team_token"
        testflight.builder.should==subject
        testflight.lists.should==["List1", "List2"]
        testflight.notes.should=="some notes"
      end
    end

    describe "#test" do

      let(:configuration) do
        Xcode.project('TestProject').target('LogicTests').config('Debug')
      end

      let(:iphonesimulator_test_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk iphonesimulator"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd.env["TEST_AFTER_BUILD"]="YES"
        cmd.env["ONLY_ACTIVE_ARCH"]="NO"
        cmd
      end

      let(:macosx_test_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk macosx10.7"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd.env["TEST_AFTER_BUILD"]="YES"
        cmd.env["ONLY_ACTIVE_ARCH"]="NO"
        cmd
      end


      it "should be able to run the test target on iphonesimulator" do
        PTY.stub(:spawn).and_return(iphonesimulator_test_parameters.to_s)
        subject.test :sdk => 'iphonesimulator'
      end

      it "should allow the override of the sdk" do
        PTY.stub(:spawn).and_return(macosx_test_parameters.to_s)
        subject.test :sdk => 'macosx10.7'
      end

      it "should not exit when test failed" do
        PTY.stub(:spawn)

        fake_parser = stub(:parser)
        fake_parser.stub(:failed? => true)
        fake_parser.stub(:close)
        Xcode::Test::Parsers::OCUnitParser.stub(:new => fake_parser)
        subject.test
      end

    end

    describe "#clean" do

      let(:default_clean_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk iphoneos"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "clean"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd
      end


      it "should clean the project with the default parameter" do
        PTY.stub(:spawn).and_return(default_clean_parameters.to_s)
        subject.clean
      end

    end

  end

  context "when using a builder built from a scheme" do

    let(:scheme) { Xcode.project('TestProject').scheme('TestProject') }

    let(:subject) { scheme.builder }

    describe "#build" do

      let(:default_build_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk iphoneos"
        cmd << "-project \"#{scheme.build_targets.last.project.path}\""
        cmd << "-scheme \"#{scheme.name}\""
        cmd << "-configuration \"Release\""
        cmd.env["OBJROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/Products/\""
        cmd
      end

      it "should build the project with the default parameters" do
        PTY.stub(:spawn).and_return(default_build_parameters.to_s)
        subject.build
      end

    end

    describe "#clean" do

      let(:default_clean_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-sdk iphoneos"
        cmd << "-project \"#{scheme.build_targets.last.project.path}\""
        cmd << "-scheme \"#{scheme.name}\""
        cmd << "-configuration \"Release\""
        cmd << "clean"
        cmd.env["OBJROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/Products/\""
        cmd
      end


      it "should clean the project with the default parameter" do
        PTY.stub(:spawn).and_return(default_clean_parameters.to_s)
        subject.clean
      end

    end

  end

end
