module Xcode
  module Builder
    class ProjectSchemeBuilder < BaseBuilder
      attr_accessor :project, :scheme
  
      def initialize(project, scheme)
        @project    = project
        @scheme     = scheme
        
        super @scheme.launch
      end
  
      def build_command(options = {})
        options = {:sdk => @sdk}.merge options
        profile = install_profile
        cmd = []
        cmd << "xcodebuild"
        cmd << "-sdk #{options[:sdk]}" unless options[:sdk].nil?
        cmd << "-project \"#{@project.path}\""
        cmd << "-scheme \"#{@scheme.name}\""
    
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