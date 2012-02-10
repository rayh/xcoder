require 'json'
require 'xcode/target'
require 'xcode/configuration'
require 'xcode/scheme'
require 'plist'

module Xcode
  class Project 
    attr_reader :name, :targets, :sdk, :path, :schemes, :groups
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @targets = []
      @schemes = []
      @groups = []
      @name = File.basename(@path).gsub(/\.xcodeproj/,'')

      parse_pbxproj
      parse_schemes
#      parse_configurations
    end
    
    def group(name)
      
    end
    
    def save
      # Save modified groups/f
    end
    
    def scheme(name)
      scheme = @schemes.select {|t| t.name == name.to_s}.first
      raise "No such scheme #{name}, available schemes are #{@schemes.map {|t| t.name}.join(', ')}" if scheme.nil?
      yield scheme if block_given?
      scheme
    end
        
    def target(name)
      target = @targets.select {|t| t.name == name.to_s}.first
      raise "No such target #{name}, available targets are #{@targets.map {|t| t.name}.join(', ')}" if target.nil?
      yield target if block_given?
      target
    end
    
    def describe
      puts "Project #{name} contains"
      targets.each do |t|
        puts " + target:#{t.name}"
        t.configs.each do |c|
          puts "    + config:#{c.name}"
        end
      end
      schemes.each do |s|
        puts " + scheme #{s.name}"
        puts "    + Launch action => target:#{s.launch.target.name}, config:#{s.launch.name}" unless s.launch.nil?
        puts "    + Test action   => target:#{s.test.target.name}, config:#{s.test.name}" unless s.test.nil?
      end
    end
    
    private
  
    def parse_schemes
      # schemes are in project/**/xcschemes/*.xcscheme
      Dir["#{@path}/**/xcschemes/*.xcscheme"].each do |scheme|
        @schemes << Xcode::Scheme.new(self, scheme)
      end
    end
  
    def parse_pbxproj
      xml = `plutil -convert xml1 -o - "#{@path}/project.pbxproj"`
      # json = JSON.parse()
      json = Plist::parse_xml(xml)
      
      root = json['objects'][json['rootObject']]

      root['targets'].each do |target_id|
        target = Xcode::Target.new(self, json['objects'][target_id])
        
        buildConfigurationList = json['objects'][target_id]['buildConfigurationList']
        buildConfigurations = json['objects'][buildConfigurationList]['buildConfigurations']
        
        buildConfigurations.each do |buildConfiguration|
          target.configs << Xcode::Configuration.new(target, json['objects'][buildConfiguration])
        end
                
        @targets << target
      end
    end

  end
end
