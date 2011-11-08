module Xcode
  class Builder
    attr_accessor :profile, :identity
    
    def initialize(config)
      @target = config.target
      @config = config
    end
    
    def install_profile
      # TODO: remove other profiles for the same app?
      Xcode.import_provisioning_profile  @profile unless @profile.nil?
    end
    
    def build
      install_profile
      
      cmd = []
      cmd << "xcodebuild"
      cmd << "-sdk #{@target.project.sdk}" unless @target.project.sdk.nil?
      cmd << "-project \"#{@target.project.path}\""
      cmd << "-target \"#{@target.name}\""
      cmd << "-configuration \"#{@config.name}\""
      Xcode::Shell.execute(cmd)
    end
    
    def clean
      cmd = []
      cmd << "xcodebuild"
      cmd << "-project \"#{@target.project.path}\""
      cmd << "-target \"#{@target.name}\""
      cmd << "-configuration \"#{@config.name}\""
      cmd << "clean"
      Xcode::Shell.execute(cmd)
      
      cmd = []
      cmd << "rm -Rf #{build_path}"
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
      
      unless @identity.nil?
        cmd << "--sign \"#{@identity}\""
      end
      
      unless @profile.nil?
        cmd << "--embed \"#{@profile}\""
      end
      
      Xcode::Shell.execute(cmd)
      
      # package dSYM
      cmd = []
      cmd << "zip"
      cmd << "-r"
      cmd << "-T"
      cmd << "-y #{dsym_zip_path}"
      cmd << "#{dsym_path}"
      Xcode::Shell.execute(cmd)
    end
    
    def build_path
      "#{File.dirname(@target.project.path)}/build/"
    end
    
    def configuration_build_path
      "#{build_path}/#{@config.name}-#{@target.project.sdk}"
    end
    
    def entitlements_path
      "#{build_path}/#{@target.name}.build/#{name}-#{@target.project.sdk}/#{@target.name}.build/#{product_name}.xcent"
    end
    
    def app_path
      "#{configuration_build_path}/#{product_name}.app"
    end

    def ipa_path
      "#{configuration_build_path}/#{product_name}-#{name}-#{info_plist.version}.ipa"
    end
    
    def dsym_path
      "#{app_path}.dSYM"
    end
    
    def dsym_zip_path
      "#{configuration_build_path}/#{product_name}-#{name}-#{info_plist.version}.dSYM.zip"
    end
    
  end
end