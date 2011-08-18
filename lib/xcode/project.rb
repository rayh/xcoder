require 'json'
require 'xcode/target'
require 'xcode/configuration'

module Xcode
  class Project 
    attr_reader :targets, :sdk, :path
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @targets = {}

      parse_pbxproj
#      parse_configurations
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
      cmd << "-project \"#{@path}\""
      cmd << cmd_line unless cmd_line.nil?
      yield cmd if block_given?
      
      execute(cmd.join(' '), show_output)
    end
    
    def target(name)
      target = @targets[name.to_s.to_sym]
      raise "No such target #{name}, available targets are #{@targets.keys}" if target.nil?
      yield target if block_given?
      target
    end
    
    private
  
    def parse_pbxproj
      json = JSON.parse(`plutil -convert json -o - "#{@path}/project.pbxproj"`)
      
      root = json['objects'][json['rootObject']]
      root['targets'].each do |target_id|
        target = Xcode::Target.new(self, json['objects'][target_id])
        
        buildConfigurationList = json['objects'][target_id]['buildConfigurationList']
        buildConfigurations = json['objects'][buildConfigurationList]['buildConfigurations']
        
        buildConfigurations.each do |buildConfiguration|
          config = Xcode::Configuration.new(target, json['objects'][buildConfiguration])
          target.configs[config.name.to_sym] = config
        end
                
        @targets[target.name.to_sym] = target
      end
    end
    
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

  end
end
