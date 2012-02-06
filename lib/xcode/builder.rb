require 'xcode/shell'
require 'xcode/provisioning_profile'

module Xcode
  class Builder
    attr_accessor :profile, :identity, :build_path, :keychain
    
    def initialize(config)
      if config.is_a? Xcode::Scheme
        @scheme = config
        config = config.launch
      end
      @target = config.target
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
    
    def build
      profile = install_profile
      
      cmd = []
      cmd << "xcodebuild"
      cmd << "-sdk #{@target.project.sdk}" unless @target.project.sdk.nil?
      cmd << "-project \"#{@target.project.path}\""
      
      cmd << "-scheme #{@scheme.name}" unless @scheme.nil?
      cmd << "-target \"#{@target.name}\"" if @scheme.nil?
      cmd << "-configuration \"#{@config.name}\"" if @scheme.nil?
      
      cmd << "OTHER_CODE_SIGN_FLAGS=\"--keychain #{@keychain.path}\"" unless @keychain.nil?
      cmd << "CODE_SIGN_IDENTITY=\"#{@identity}\"" unless @identity.nil?
      cmd << "OBJROOT=\"#{@build_path}\""
      cmd << "SYMROOT=\"#{@build_path}\""
      cmd << "PROVISIONING_PROFILE=#{profile.uuid}" unless profile.nil?
      yield(cmd) if block_given?
      
      Xcode::Shell.execute(cmd)
    end
    
    def test
      build do |cmd|
        cmd.select! do |line|
          !line=~/\^-sdk/
        end
        
        cmd << "TEST_AFTER_BUILD=YES"
        cmd << "TEST_HOST=''"
        cmd << "-sdk iphonesimulator5.0"  # FIXME: hardcoded version, should be smarter
      end
      
      Xcode::Shell.execute(cmd)
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
      "#{build_path}/#{@config.name}-#{@target.project.sdk}"
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
    
  end
end