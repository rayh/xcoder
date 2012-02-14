require 'xcode/shell'
require 'xcode/provisioning_profile'
require 'xcode/test/ocunit_report_parser.rb'
require 'xcode/testflight'

module Xcode
  class Builder
    attr_accessor :profile, :identity, :build_path, :keychain, :sdk
    
    def initialize(config)
      if config.is_a? Xcode::Scheme
        @scheme = config
        config = config.launch
      end
      
      #puts "CONFIG: #{config}"
      @target = config.target
      @sdk = @target.project.sdk
      @config = config
      @build_path = "#{File.dirname(@target.project.path)}/build/"
    end
    
    def install_profile
      return nil if @profile.nil?
      # TODO: remove other profiles for the same app?
      p = ProvisioningProfile.new(@profile)
      
      ProvisioningProfile.installed_profiles.each do |installed|
        if installed.identifiers==p.identifiers and installed.uuid==p.uuid
          installed.uninstall
        end
      end
      
      p.install
      p
    end
    
    def build(sdk=@sdk)    
      cmd = build_command(@sdk)
      Xcode::Shell.execute(cmd)
    end
    
    def test
      cmd = build_command('iphonesimulator')
      cmd << "TEST_AFTER_BUILD=YES"
      cmd << "TEST_HOST=''"
      
      parser = Xcode::Test::OCUnitReportParser.new
      Xcode::Shell.execute(cmd, false) do |line|
        puts line
        parser << line
      end
      
      yield(parser) if block_given?
      
      exit parser.exit_code if parser.exit_code!=0
      
      parser
    end
    
    def testflight(api_token, team_token)
      raise "Can't find #{ipa_path}, do you need to call builder.build?" unless File.exists? ipa_path
      raise "Can't fins #{dsym_zip_path}, do you need to call builder.build?" unless File.exists? dsym_zip_path
      
      testflight = Xcode::Testflight.new(api_token, team_token)
      yield(testflight) if block_given?
      testflight.upload(ipa_path, dsym_zip_path)
    end
    
    def clean
      cmd = []
      cmd << "xcodebuild"
      cmd << "-project \"#{@target.project.path}\""
      
      cmd << "-scheme #{@scheme.name}" unless @scheme.nil?
      cmd << "-target \"#{@target.name}\"" if @scheme.nil?
      cmd << "-configuration \"#{@config.name}\"" if @scheme.nil?
      
      cmd << "OBJROOT=\"#{@build_path}\""
      cmd << "SYMROOT=\"#{@build_path}\""
      cmd << "clean"
      Xcode::Shell.execute(cmd)
      
      @built = false
      @packaged = false
      # FIXME: Totally not safe
      # cmd = []
      # cmd << "rm -Rf #{build_path}"
      # Xcode::Shell.execute(cmd)
    end    
    
    def sign
      cmd = []
      cmd << "codesign"
      cmd << "--force"
      cmd << "--sign \"#{@identity}\""
      cmd << "--resource-rules=\"#{app_path}/ResourceRules.plist\""
      cmd << "--entitlements \"#{entitlements_path}\""
      cmd << "\"#{ipa_path}\""
      Xcode::Shell.execute(cmd)
    end
    
    def package
      raise "Can't find #{app_path}, do you need to call builder.build?" unless File.exists? app_path
      
      #package IPA
      cmd = []      
      cmd << "xcrun"
      cmd << "-sdk #{@target.project.sdk.nil? ? "iphoneos" : @target.project.sdk}"
      cmd << "PackageApplication"
      cmd << "-v \"#{app_path}\""
      cmd << "-o \"#{ipa_path}\""
      
      # cmd << "OTHER_CODE_SIGN_FLAGS=\"--keychain #{@keychain.path}\"" unless @keychain.nil?
      # 
      # unless @identity.nil?
      #   cmd << "--sign \"#{@identity}\""
      # end
      
      unless @profile.nil?
        cmd << "--embed \"#{@profile}\""
      end
      
      Xcode::Shell.execute(cmd)
      
      # package dSYM
      cmd = []
      cmd << "zip"
      cmd << "-r"
      cmd << "-T"
      cmd << "-y \"#{dsym_zip_path}\""
      cmd << "\"#{dsym_path}\""
      Xcode::Shell.execute(cmd)

    end
    
    def configuration_build_path
      "#{build_path}/#{@config.name}-#{@sdk}"
    end
    
    def entitlements_path
      "#{build_path}/#{@target.name}.build/#{name}-#{@target.project.sdk}/#{@target.name}.build/#{@config.product_name}.xcent"
    end
    
    def app_path
      "#{configuration_build_path}/#{@config.product_name}.app"
    end
    
    def product_version_basename
      version = @config.info_plist.version
      version = "SNAPSHOT" if version.nil? or version==""
      "#{configuration_build_path}/#{@config.product_name}-#{@config.name}-#{version}"
    end

    def ipa_path
      "#{product_version_basename}.ipa"
    end
    
    def dsym_path
      "#{app_path}.dSYM"
    end
    
    def dsym_zip_path
      "#{product_version_basename}.dSYM.zip"
    end
    
    
    private 
    
    def build_command(sdk=@sdk)
      profile = install_profile
      cmd = []
      cmd << "xcodebuild"
      cmd << "-sdk #{sdk}" unless sdk.nil?
      cmd << "-project \"#{@target.project.path}\""
      
      cmd << "-scheme #{@scheme.name}" unless @scheme.nil?
      cmd << "-target \"#{@target.name}\"" if @scheme.nil?
      cmd << "-configuration \"#{@config.name}\"" if @scheme.nil?
      
      cmd << "OTHER_CODE_SIGN_FLAGS=\"--keychain #{@keychain.path}\"" unless @keychain.nil?
      cmd << "CODE_SIGN_IDENTITY=\"#{@identity}\"" unless @identity.nil?
      cmd << "OBJROOT=\"#{@build_path}\""
      cmd << "SYMROOT=\"#{@build_path}\""
      cmd << "PROVISIONING_PROFILE=#{profile.uuid}" unless profile.nil?
      cmd
    end
    
  end
end