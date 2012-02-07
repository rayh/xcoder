require 'rspec'
require 'xcoder'

describe Xcode::Builder do 
  
  context "when using a builder built from a configuration" do

    let(:configuration) { Xcode.project('TestProject').target('TestProject').config('Debug') }

    let(:subject) { configuration.builder }

    describe "#build" do

      let(:default_build_parameters) do
        [ "xcodebuild", 
          "-sdk #{configuration.target.project.sdk}", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"" ]
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters)
        subject.build
      end

      context "when additional parameters have been specified" do

        it "should add new parameters" do

          expected_build_parameters = default_build_parameters + [ "-additionalparameter=value" ]

          Xcode::Shell.should_receive(:execute).with(expected_build_parameters)

          subject.build do |parameters|
            parameters << "-additionalparameter=value"
          end

        end

        let(:overridden_build_parameters) do
          [ "xcodebuild", 
            "-sdk newiossdk", 
            "-project \"#{configuration.target.project.path}\"", 
            "-target \"#{configuration.target.name}\"", 
            "-configuration \"#{configuration.name}\"", 
            "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
            "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"" ]
        end

        it "should override existing parameters" do

          Xcode::Shell.should_receive(:execute).with(overridden_build_parameters)

          subject.build do |parameters|
            parameters << "-sdk newiossdk"
          end

        end

        it "should support additional environment variables" do

          expected_build_parameters = default_build_parameters + [ "ENVIRONMENTVARIABLE=NEWVARIABLE" ]

          Xcode::Shell.should_receive(:execute).with(expected_build_parameters)

          subject.build do |parameters|
            parameters << "ENVIRONMENTVARIABLE=NEWVARIABLE"
          end

        end

      end

    end

    describe "#clean" do

      let(:default_clean_parameters) do
        [ "xcodebuild", 
          "-project \"#{configuration.target.project.path}\"", 
          "-target \"#{configuration.target.name}\"", 
          "-configuration \"#{configuration.name}\"", 
          "OBJROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(configuration.target.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parametesr" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters)
        subject.clean
      end

    end

  end
  
  context "when using a builder built from a scheme" do

    let(:scheme) { Xcode.project('TestProject').scheme('TestProject') }
    
    let(:subject) { scheme.builder }

    describe "#build" do

      let(:default_build_parameters) do
        [ "xcodebuild",
          "-sdk iphoneos",
          "-project \"#{scheme.project.path}\"",
          "-scheme #{scheme.name}",
          "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"" ]
      end

      it "should build the project with the default parameters" do
        Xcode::Shell.should_receive(:execute).with(default_build_parameters)
        subject.build
      end

      context "when additional parameters have been specified" do

        it "should add new parameters" do

          expected_build_parameters = default_build_parameters + [ "-additionalparameter=value" ]

          Xcode::Shell.should_receive(:execute).with(expected_build_parameters)

          subject.build do |parameters|
            parameters << "-additionalparameter=value"
          end

        end

        let(:overridden_build_parameters) do
          [ "xcodebuild",
            "-sdk newiossdk",
            "-project \"#{scheme.project.path}\"",
            "-scheme #{scheme.name}",
            "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
            "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"" ]
        end

        it "should override existing parameters" do

          Xcode::Shell.should_receive(:execute).with(overridden_build_parameters)

          subject.build do |parameters|
            parameters << "-sdk newiossdk"
          end

        end

        it "should support additional environment variables" do

          expected_build_parameters = default_build_parameters + [ "ENVIRONMENTVARIABLE=NEWVARIABLE" ]

          Xcode::Shell.should_receive(:execute).with(expected_build_parameters)

          subject.build do |parameters|
            parameters << "ENVIRONMENTVARIABLE=NEWVARIABLE"
          end

        end

      end
      
    end
    
    describe "#clean" do

      let(:default_clean_parameters) do
        [ "xcodebuild",
          "-project \"#{scheme.project.path}\"",
          "-scheme #{scheme.name}",
          "OBJROOT=\"#{File.dirname(scheme.project.path)}/build/\"", 
          "SYMROOT=\"#{File.dirname(scheme.project.path)}/build/\"",
          "clean" ]
      end


      it "should clean the project with the default parametesr" do
        Xcode::Shell.should_receive(:execute).with(default_clean_parameters)
        subject.clean
      end

    end
    
    # it "should be able to build" do
    #   builder = @scheme.builder
    #   builder.clean
    #   builder.build
    #   File.exists?(builder.app_path).should==true
    #   File.exists?(builder.dsym_path).should==true
    # end
    # 
    # it "should be able to package" do
    #   builder = @scheme.builder
    #   builder.clean
    #   builder.build
    #   builder.package
    #   File.exists?(builder.dsym_zip_path).should==true
    #   File.exists?(builder.ipa_path).should==true
    # end

  end
  
end