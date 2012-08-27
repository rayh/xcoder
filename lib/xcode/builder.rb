require 'xcode/shell'
require 'xcode/provisioning_profile'
require 'xcode/test/parsers/ocunit_parser.rb'
require 'xcode/testflight'

module Xcode

  #
  # This class tries to pull various bits of Xcoder together to provide a higher-level API for common 
  # project build tasks.
  #
  class Builder
    attr_accessor :profile, :identity, :build_path, :keychain, :sdk, :objroot, :symroot
    
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
      @objroot = @build_path
      @symroot = @build_path
    end
    
    
    def build(options = {:sdk => @sdk})    
      cmd = build_command(options)
      with_keychain do
        Xcode::Shell.execute(cmd)
      end
      self
    end
     
    # 
    # Invoke the configuration's test target and parse the resulting output
    #
    # If a block is provided, the report is yielded for configuration before the test is run
    #
    def test(options = {:sdk => 'iphonesimulator'}) #, :parser => :OCUnit })
      cmd = build_command(options)
      cmd << "TEST_AFTER_BUILD=YES"
      
      report = Xcode::Test::Report.new
      if block_given?
        yield(report)
      else
        report.add_formatter :stdout
        report.add_formatter :junit, 'test-reports'
      end
      
      parser = Xcode::Test::Parsers::OCUnitParser.new report
      
      begin
        Xcode::Shell.execute(cmd, false) do |line|
          parser << line
        end
      rescue Xcode::Shell::ExecutionError => e
        puts "Test platform exited: #{e.message}"
      ensure
        parser.flush
      end
      
      report
    end
    
    def testflight(api_token, team_token)
      raise "Can't find #{ipa_path}, do you need to call builder.package?" unless File.exists? ipa_path
      raise "Can't fins #{dsym_zip_path}, do you need to call builder.package?" unless File.exists? dsym_zip_path
      
      testflight = Xcode::Testflight.new(api_token, team_token)
      yield(testflight) if block_given?
      testflight.upload(ipa_path, dsym_zip_path)
    end
    
    def clean
      cmd = []
      cmd << "xcodebuild"
      cmd << "-project \"#{@target.project.path}\""
      cmd << "-sdk #{@sdk}" unless @sdk.nil?
      
      cmd << "-scheme \"#{@scheme.name}\"" unless @scheme.nil?
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
      self
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
 
# CodeSign build/AdHoc-iphoneos/Dial.app
#     cd "/Users/ray/Projects/Clients/CBAA/Community Radio"
#     setenv CODESIGN_ALLOCATE /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate
#     setenv PATH "/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin:/Developer/usr/bin:/Users/ray/.rvm/gems/ruby-1.9.2-p290@cbaa/bin:/Users/ray/.rvm/gems/ruby-1.9.2-p290@global/bin:/Users/ray/.rvm/rubies/ruby-1.9.2-p290/bin:/Users/ray/.rvm/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/local/git/bin"
#     /usr/bin/codesign --force --sign "iPhone Distribution: Community Broadcasting Association of Australia" "--resource-rules=/Users/ray/Projects/Clients/CBAA/Community Radio/build/AdHoc-iphoneos/Dial.app/ResourceRules.plist" --keychain "\"/Users/ray/Projects/Clients/CBAA/Community\\" "Radio/Provisioning/CBAA.keychain\"" --entitlements "/Users/ray/Projects/Clients/CBAA/Community Radio/build/CommunityRadio.build/AdHoc-iphoneos/CommunityRadio.build/Dial.xcent" "/Users/ray/Projects/Clients/CBAA/Community Radio/build/AdHoc-iphoneos/Dial.app"
# iPhone Distribution: Community Broadcasting Association of Australia: no identity found
# Command /usr/bin/codesign failed with exit code 1
      self
    end
    
    def package
      raise "Can't find #{app_path}, do you need to call builder.build?" unless File.exists? app_path
      
      #package IPA
      cmd = []      
      cmd << "xcrun"
      cmd << "-sdk #{@sdk}" unless @sdk.nil?
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
      
      with_keychain do
        Xcode::Shell.execute(cmd)
      end
      
      # package dSYM
      cmd = []
      cmd << "zip"
      cmd << "-r"
      cmd << "-T"
      cmd << "-y \"#{dsym_zip_path}\""
      cmd << "\"#{dsym_path}\""
      Xcode::Shell.execute(cmd)

      self
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
    
    def with_keychain(&block)
      if @keychain.nil?
        yield
      else
        Xcode::Keychains.with_keychain_in_search_path @keychain, &block
      end
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
    
    def build_command(options = {})
      options = {:sdk => @sdk, :env => {}}.merge options
      profile = install_profile
      cmd = []
      cmd << "xcodebuild"
      cmd << "-sdk #{options[:sdk]}" unless options[:sdk].nil?
      cmd << "-project \"#{@target.project.path}\""
      
      cmd << "-scheme \"#{@scheme.name}\"" unless @scheme.nil?
      cmd << "-target \"#{@target.name}\"" if @scheme.nil?
      cmd << "-configuration \"#{@config.name}\"" if @scheme.nil?
      
      cmd << "OTHER_CODE_SIGN_FLAGS='--keychain #{@keychain.path}'" unless @keychain.nil?
      cmd << "CODE_SIGN_IDENTITY=\"#{@identity}\"" unless @identity.nil?
      cmd << "OBJROOT=\"#{@objroot}\""
      cmd << "SYMROOT=\"#{@symroot}\""
      cmd << "PROVISIONING_PROFILE=#{profile.uuid}" unless profile.nil?

      options[:env].each_pair do |key, value|
        cmd << "#{key}=\"#{value}\""
      end

      cmd
    end
    
  end
end
