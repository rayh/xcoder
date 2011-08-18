module Xcode
  class Project 
    attr_reader :targets, :configurations, :sdk, :path
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      puts @path
      @targets = []
      @configurations = []

      parse_targets
      parse_configurations
    end
    
    def build(target, config) # :yield: object representing the build
      build = Xcode::Build.new(self, target, config)
      if block_given?
        yield build
      else
        build.build
      end
      build
    end
  
    def execute_package_application(options=nil)
      cmd = []
      cmd << "xcrun"
      cmd << "-sdk #{@sdk.nil? ? "iphoneos" : @sdk}"
      cmd << "PackageApplication"
      cmd << options unless options.nil?
  
      execute(cmd.join(' '), true)
    end
  
    def execute_xcodebuild(cmd_line=nil, show_output=true)
      cmd = []
      cmd << "xcodebuild"
      cmd << "-sdk #{@sdk}" unless @sdk.nil?
      cmd << "-project #{@path}"
      cmd << cmd_line unless cmd_line.nil?
      yield cmd if block_given?
      
      execute(cmd.join(' '), show_output)
    end
    
    private
    
    def execute(cmd, show_output=false)
      out = []
      puts "EXECUTE: #{cmd}"
      IO.popen (cmd) do |f| 
        f.each do |line|
          puts line if show_output
          out << line
        end 
      end
      #puts "RETURN: #{out.inspect}"
      out
    end

    def parse_targets
      parsing = false
      execute_xcodebuild("-list", false).each do |l|
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
      execute_xcodebuild("-list", false).each do |l|
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

  end
end
