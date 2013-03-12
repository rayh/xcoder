module Xcode
  module Builder
    #
    # This class tries to pull various bits of Xcoder together to provide a higher-level API for common
    # project build tasks.
    #
    class BaseBuilder
      attr_accessor :profile, :identity, :build_path, :keychain, :sdk, :objroot, :symroot
      attr_reader   :config, :target

      def initialize(target, config)
        @target = target
        @config = config

        @sdk = @target.project.sdk
        @build_path = "#{File.dirname(@target.project.path)}/build/"
        @objroot = @build_path
        @symroot = @build_path
      end

      def common_environment
        env = {}
        env["OBJROOT"]  = "\"#{@objroot}\""
        env["SYMROOT"]  = "\"#{@symroot}\""
        env
      end

      def build_environment
        profile = install_profile
        env = common_environment
        env["OTHER_CODE_SIGN_FLAGS"]  = "'--keychain #{@keychain.path}'" unless @keychain.nil?
        env["CODE_SIGN_IDENTITY"]     = "\"#{@identity}\"" unless @identity.nil?
        env["PROVISIONING_PROFILE"]   = "#{profile.uuid}" unless profile.nil?
        env
      end


      def build(options = {:sdk => @sdk}, show_output, &block)
        cmd = xcodebuild
        cmd << "-sdk #{options[:sdk]}" unless options[:sdk].nil?

        with_keychain do
          cmd.execute(show_output, &block)
        end
        self
      end

      #
      # Invoke the configuration's test target and parse the resulting output
      #
      # If a block is provided, the report is yielded for configuration before the test is run
      #
      def test(options = {:sdk => 'iphonesimulator'})
        cmd = xcodebuild
        cmd << "-sdk #{options[:sdk]}" unless options[:sdk].nil?
        cmd.env["TEST_AFTER_BUILD"]="YES"

        report = Xcode::Test::Report.new
        if block_given?
          yield(report)
        else
          report.add_formatter :stdout, { :color_output => true }
          report.add_formatter :junit, 'test-reports'
        end

        parser = Xcode::Test::Parsers::OCUnitParser.new report

        begin
          cmd.execute(false) do |line|
            parser << line
          end
        rescue Xcode::Shell::ExecutionError => e
          puts "Test platform exited: #{e.message}" if report.suites.count==0
        ensure
          parser.flush
        end

        report
      end

      #
      # Deploy the package through the chosen method
      #
      # @param method the deployment method (web, ssh, testflight)
      # @param options options specific for the chosen deployment method
      #
      def deploy method, options = {}
        options = {
          :ipa_path => ipa_path,
          :dsym_zip_path => dsym_zip_path,
          :ipa_name => ipa_name,
          :app_path => app_path,
          :configuration_build_path => configuration_build_path,
          :product_name => @config.product_name,
          :info_plist => @config.info_plist
        }.merge options

        require "xcode/deploy/#{method.to_s}.rb"
        deployer = Xcode::Deploy.const_get("#{method.to_s.capitalize}").new(builder, options)

        # yield(deployer) if block_given?
        deployer.deploy builder, &block
      end

      #
      # Upload to testflight
      #
      # The testflight object is yielded so further configuration can be performed before uploading
      #
      # @param api_token the API token for your testflight account
      # @param team_token the token for the team you want to deploy to
      #
      def testflight(api_token, team_token)
        raise "Can't find #{ipa_path}, do you need to call builder.package?" unless File.exists? ipa_path
        raise "Can't find #{dsym_zip_path}, do you need to call builder.package?" unless File.exists? dsym_zip_path

        testflight = Xcode::Deploy::Testflight.new(api_token, team_token)
        yield(testflight) if block_given?
        testflight.upload(ipa_path, dsym_zip_path)
      end

      def clean(show_output = true, &block)
        cmd = xcodebuild
        cmd << "-sdk #{@sdk}" unless @sdk.nil?
        cmd << "clean"
        cmd.execute(show_output, &block)

        @built = false
        @packaged = false
        self
      end

      def sign(show_output = true, &block)
        cmd = Xcode::Shell::Command.new 'codesign'
        cmd << "--force"
        cmd << "--sign \"#{@identity}\""
        cmd << "--resource-rules=\"#{app_path}/ResourceRules.plist\""
        cmd << "--entitlements \"#{entitlements_path}\""
        cmd << "\"#{ipa_path}\""
        cmd.execute(show_output, &block)

        self
      end

      def package(show_output = true, &block)
        raise "Can't find #{app_path}, do you need to call builder.build?" unless File.exists? app_path

        #package IPA
        cmd = Xcode::Shell::Command.new 'xcrun'
        cmd << "-sdk #{@sdk}" unless @sdk.nil?
        cmd << "PackageApplication"
        cmd << "-v \"#{app_path}\""
        cmd << "-o \"#{ipa_path}\""

        unless @profile.nil?
          cmd << "--embed \"#{@profile}\""
        end

        with_keychain do
          cmd.execute(show_output, &block)
        end

        # package dSYM
        cmd = Xcode::Shell::Command.new 'zip'
        cmd << "-r"
        cmd << "-T"
        cmd << "-y \"#{dsym_zip_path}\""
        cmd << "\"#{dsym_path}\""
        cmd.execute(show_output, &block)

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

      def product_name
        @config.product_name
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

      def ipa_name
        File.basename(ipa_path)
      end

      def bundle_identifier
        @config.info_plist.identifier
      end

      def bundle_version
        @config.info_plist.version
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

      def xcodebuild #:yield: Xcode::Shell::Command
        Xcode::Shell::Command.new 'xcodebuild', build_environment
      end

    end
  end
end
