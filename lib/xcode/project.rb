module Xcode
  class Project 
    attr_reader :targets, :name, :dir, :configurations
    def initialize(dir, project_name)
      @dir = dir
      @name = project_name
      @targets = []
      @configurations = []

      parse_targets
      parse_configurations
    end

    def build(target, config, sdk=nil)
      raise "Target #{target} is not valid, should be one of #{@targets}" unless @targets.include? target
      raise "Configuration #{config} is not valid, should be one of #{@configurations}" unless @configurations.include? config
      cmd = xcode_cmd("-target #{target} -configuration #{config}")
      cmd = "#{cmd} -sdk #{sdk}" unless sdk.nil?
      `#{cmd}`
    end
  
    def package(filename)
#      "xcrun -sdk iphoneos PackageApplication -v "$APP_FILENAME" -o "$BUILD_DIRECTORY/$IPA_FILENAME" --sign "$DISTRIBUTION_CERTIFICATE" --embed "$PROVISIONING_PROFILE_PATH""
    end
  
    private

    def parse_targets
      parsing = false
      `#{xcode_cmd} -list`.split("\n").each do |l|
        l.strip!
        if l=~/Targets/
  	      parsing = true
        elsif l=~/^\s*$/
          parsing = false
        elsif parsing
  	      l=~/([^\s]+)(\s\(.*\))?/
          @targets << $1
        end
      end
    end

    def parse_configurations
      parsing = false
      `#{xcode_cmd} -list`.split("\n").each do |l|
        l.strip!
        if l=~/Build\ Configurations/
  	      parsing = true
        elsif l=~/^\s*$/
          parsing = false
        elsif parsing
  	      l=~/([^\s]+)(\s\(.*\))?/
          @configurations << $1
        end
      end
    end

    def xcode_cmd(options=nil)
      cmd = "xcodebuild"
      cmd = "#{cmd} -project #{dir}/#{@name}.xcodeproj" unless @name.nil?
      cmd = "#{cmd} #{options}" unless options.nil?
      cmd
    end

  end
end