module Xcode
  module Builder
    class ProjectTargetConfigBuilder < BaseBuilder
      attr_accessor :config
  
      def initialize(config)
        @config     = config
      end
  
      def build_command(options = {})
        options = {:sdk => @sdk}.merge options
        profile = install_profile
        cmd = []
        cmd << "xcodebuild"
        cmd << "-sdk #{options[:sdk]}" unless options[:sdk].nil?
        cmd << "-project \"#{@config.target.project.path}\""
        cmd << "-target \"#{@config.target.name}\""
        cmd << "-config \"#{@config.name}\""
    
        cmd << "OTHER_CODE_SIGN_FLAGS='--keychain #{@keychain.path}'" unless @keychain.nil?
        cmd << "CODE_SIGN_IDENTITY=\"#{@identity}\"" unless @identity.nil?
        cmd << "OBJROOT=\"#{@objroot}\""
        cmd << "SYMROOT=\"#{@symroot}\""
        cmd << "PROVISIONING_PROFILE=#{profile.uuid}" unless profile.nil?
        cmd
      end
    end
  end
end