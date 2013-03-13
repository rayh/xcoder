require_relative 'spec_helper'

describe Xcode::Builder do

  context "when using a builder built from a configuration" do

    let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }

    let(:subject) { configuration.builder }

    describe "#build" do

      let(:default_build_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "-sdk #{configuration.target.project.sdk}"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd
      end

      let(:macosx_build_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "-sdk macosx10.7"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters,false)
        subject.build
      end

      it "should allow the override of the sdk" do
        Xcode::Shell.should_receive(:execute).with(macosx_build_parameters, false)
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
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "-sdk iphonesimulator"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd.env["TEST_AFTER_BUILD"]="YES"
        cmd
      end

      let(:macosx_test_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "-sdk macosx10.7"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd.env["TEST_AFTER_BUILD"]="YES"
        cmd
      end


      it "should be able to run the test target on iphonesimulator" do
        Xcode::Shell.should_receive(:execute).with(iphonesimulator_test_parameters, false)
        subject.test :sdk => 'iphonesimulator'
      end

      it "should allow the override of the sdk" do
        Xcode::Shell.should_receive(:execute).with(macosx_test_parameters, false)
        subject.test :sdk => 'macosx10.7'
      end

      it "should not exit when test failed" do
        Xcode::Shell.stub(:execute)
        fake_parser = stub(:parser)
        fake_parser.stub(:failed? => true)
        fake_parser.stub(:flush)
        Xcode::Test::Parsers::OCUnitParser.stub(:new => fake_parser)
        subject.test
      end

    end

    describe "#clean" do

      let(:default_clean_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-project \"#{configuration.target.project.path}\""
        cmd << "-target \"#{configuration.target.name}\""
        cmd << "-config \"#{configuration.name}\""
        cmd << "-sdk iphoneos"
        cmd << "clean"
        cmd.env["OBJROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(configuration.target.project.path)}/Build/Products/\""
        cmd
      end


      it "should clean the project with the default parameter" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters, false)
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
        cmd << "-project \"#{scheme.build_targets.last.project.path}\""
        cmd << "-scheme \"#{scheme.name}\""
        cmd << "-sdk iphoneos"
        cmd.env["OBJROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/Products/\""
        cmd
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters, false)
        subject.build
      end

    end

    describe "#clean" do

      let(:default_clean_parameters) do
        cmd = Xcode::Shell::Command.new "xcodebuild"
        cmd << "-project \"#{scheme.build_targets.last.project.path}\""
        cmd << "-scheme \"#{scheme.name}\""
        cmd << "-sdk iphoneos"
        cmd << "clean"
        cmd.env["OBJROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/\""
        cmd.env["SYMROOT"]="\"#{File.dirname(scheme.build_targets.last.project.path)}/Build/Products/\""
        cmd
      end


      it "should clean the project with the default parameter" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters, false)
        subject.clean
      end

    end

  end

end
