require 'json'
require 'xcode/target'
require 'xcode/configuration'

module Xcode
  class Project 
    attr_reader :name, :targets, :sdk, :path
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @targets = {}
      @name = File.basename(@path).gsub(/\.xcodeproj/,'')

      parse_pbxproj
#      parse_configurations
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

  end
end
