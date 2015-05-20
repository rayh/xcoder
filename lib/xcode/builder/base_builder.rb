require 'xcode/builder/build_parser'

module Xcode
  module Builder
    #
    # This class tries to pull various bits of Xcoder together to provide a higher-level API for common
    # project build tasks.
    #
    class BaseBuilder
      include Xcode::TerminalOutput

      attr_accessor :profile, :identity, :build_path, :keychain, :sdk, :objroot, :symroot
      attr_reader   :config, :target

      def initialize(target, config)
        @target = target
        @config = config

        @sdk = @target.project.sdk
      end

      def profile= (value)
          if value.is_a?(ProvisioningProfile)
            @profile = value
          else
            @profile = ProvisioningProfile.new(value)
          end
      end
        
      def cocoapods_installed?
        system("which pod > /dev/null 2>&1")
      end

      def has_dependencies?
        podfile = File.join(File.dirname(@target.project.path), "Podfile")
        File.exists? podfile
      end

      #
      # If a Podfile exists, perform a pod install
      #
      def dependencies
        if has_dependencies? and cocoapods_installed?
          print_task :builder, "Fetch depencies", :notice
          podfile = File.join(File.dirname(@target.project.path), "Podfile")
   
          print_task :cocoapods, "pod setup", :info
          with_command('pod setup').execute

          print_task :cocoapods, "pod install", :info
          with_command('pod install').execute
        end
      end

      def prepare_xcodebuild sdk=@sdk #:yield: Xcode::Shell::Command
        with_command 'xcodebuild' do |cmd|

          cmd.log_to_file = true
          cmd.attach Xcode::Builder::XcodebuildParser.new
          
          cmd.env["OBJROOT"]  = "\"#{objroot}/\""
          cmd.env["SYMROOT"]  = "\"#{symroot}/\""
            
          unless profile.nil?
            profile.install
            print_task "builder", "Using profile #{profile.install_path}", :debug
            cmd.env["PROVISIONING_PROFILE"]   = "#{profile.uuid}"
          end

          unless @keychain.nil?
            print_task 'builder', "Using keychain #{@keychain.path}", :debug
            cmd.env["OTHER_CODE_SIGN_FLAGS"]  = "'--keychain #{@keychain.path}'"
          end

          unless @identity.nil?
            print_task 'builder', "Using identity #{@identity}", :debug
            cmd.env["CODE_SIGN_IDENTITY"]     = "\"#{@identity}\""
          end

          cmd << "-sdk #{sdk}" unless sdk.nil?

          yield cmd if block_given?
        end
      end      
      
      def with_command command_line
        cmd = Xcode::Shell::Command.new command_line
        cmd.output_dir = objroot
        yield cmd if block_given?
        cmd
      end

      def prepare_build_command sdk=@sdk
        cmd = prepare_xcodebuild sdk
        cmd
      end

      def prepare_test_command sdk=@sdk
        cmd = prepare_xcodebuild sdk
        cmd.env["TEST_AFTER_BUILD"]="YES"
        cmd.env["ONLY_ACTIVE_ARCH"]="NO"
        # cmd.env["TEST_HOST"]=0
        # cmd << "-sdk #{sdk}" unless sdk.nil?
        cmd
      end

      def prepare_clean_command sdk=@sdk
        cmd = prepare_xcodebuild sdk
        cmd << "clean"
        cmd
      end

      def prepare_package_command
        #package IPA
        with_command 'xcrun' do |cmd|
          cmd << "-sdk #{@sdk}" unless @sdk.nil?
          cmd << "PackageApplication"
          cmd << "-v \"#{app_path}\""
          cmd << "-o \"#{ipa_path}\""

          unless @profile.nil?
            cmd << "--embed \"#{@profile}\""
          end
        end
      end

      def prepare_dsym_command
        # package dSYM
        with_command 'zip' do |cmd|
          cmd << "-r"
          cmd << "-T"
          cmd << "-y \"#{dsym_zip_path}\""
          cmd << "\"#{dsym_path}\""
        end
      end

      #
      # Build the project
      #
      def build options = {:sdk => @sdk}, &block
        print_task :builder, "Building #{product_name}", :notice
        cmd = prepare_build_command options[:sdk]

        with_keychain do
          cmd.execute
        end

        self
      end

      #
      # Invoke the configuration's test target and parse the resulting output
      #
      # If a block is provided, the report is yielded for configuration before the test is run
      #
      # TODO: Move implementation to the Xcode::Test module
      def test options = {:sdk => @sdk, :show_output => false}
        report = Xcode::Test::Report.new
        print_task :builder, "Testing #{product_name}", :notice

        cmd = prepare_test_command options[:sdk]

        if block_given?
          yield(report)
        else
          report.add_formatter :stdout, { :color_output => true }
          report.add_formatter :junit, 'test-reports'
        end

        cmd.attach Xcode::Test::Parsers::OCUnitParser.new(report)
        cmd.show_output = options[:show_output] # override it if user wants output

        begin
          cmd.execute
        rescue Xcode::Shell::ExecutionError => e
          # FIXME: Perhaps we should always raise this?
          raise e if report.suites.count==0
        end

        report
      end

      #
      # Deploy the package through the chosen method
      #
      # @param method the deployment method (web, ssh, testflight)
      # @param options options specific for the chosen deployment method
      #
      # If a block is given, the deployer is yielded before deploy() is called
      #
      # TODO: move deployment to Xcode::Deploy module
      def deploy method, options = {}
        print_task :builder, "Deploy to #{method}", :notice
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
        deployer = Xcode::Deploy.const_get("#{method.to_s.capitalize}").new(self, options)

        yield(deployer) if block_given?

        deployer.deploy
      end

      #
      # Upload to testflight
      #
      # The testflight object is yielded so further configuration can be performed before uploading
      #
      # @param api_token the API token for your testflight account
      # @param team_token the token for the team you want to deploy to
      #
      # DEPRECATED, use deploy() instead
      # def testflight(api_token, team_token)
      #   raise "Can't find #{ipa_path}, do you need to call builder.package?" unless File.exists? ipa_path
      #   raise "Can't find #{dsym_zip_path}, do you need to call builder.package?" unless File.exists? dsym_zip_path

      #   testflight = Xcode::Deploy::Testflight.new(api_token, team_token)
      #   yield(testflight) if block_given?
      #   testflight.upload(ipa_path, dsym_zip_path)
      # end

      def clean options = {:sdk=>@sdk}, &block
        print_task :builder, "Cleaning #{product_name}", :notice
        prepare_clean_command(options[:sdk]).execute

        @built = false
        @packaged = false
        self
      end

      def package options = {}, &block
        options = {:show_output => false}.merge(options)

        raise "Can't find #{app_path}, do you need to call builder.build?" unless File.exists? app_path or File.symlink? app_path

        print_task 'builder', "Packaging #{product_name}", :notice

        print_task :package, "generating IPA: #{ipa_path}", :info
        with_keychain do
          prepare_package_command.execute
        end

        print_task :package, "creating dSYM zip: #{dsym_zip_path}", :info
        prepare_dsym_command.execute

        self
      end

      def project_root
        @target.project.path
      end

      def configuration_build_path
        "#{symroot}/#{@config.name}-#{@sdk}"
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

      def objroot
        @objroot ||= build_path
      end

      def symroot                
        @symroot ||= File.join(build_path, 'Products')
      end

      def build_path=(path)
        @build_path ||= path
        FileUtils.mkdir_p @build_path
      end

      def build_path
        return @build_path unless @build_path.nil?
        @build_path = File.join File.dirname(@target.project.path), "Build"
        FileUtils.mkdir_p @build_path
        @build_path
      end

      private

      def with_keychain(&block)
        if @keychain.nil?
          yield
        else
          Xcode::Keychains.with_keychain_in_search_path @keychain, &block
        end
      end

    end
  end
end
