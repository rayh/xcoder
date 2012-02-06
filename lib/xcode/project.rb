require 'json'
require 'xcode/resource'
require 'xcode/target'
require 'xcode/configuration'
require 'xcode/scheme'
require 'xcode/group'
require 'xcode/file'
require 'xcode/registry'

module Xcode
  class Project 
    
    attr_reader :name, :sdk, :path, :schemes, :registry
    
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @schemes = []
      @groups = []
      @name = File.basename(@path).gsub(/\.xcodeproj/,'')

      @project = parse_pbxproj
      parse_schemes
    end
    
    #
    # Returns the main group of the project where all the files reside.
    # 
    # @return [PBXGroup]
    # @see PBXGroup
    # 
    def groups
      @project.mainGroup
    end
    
    # 
    # Save the current project at the current path that it exists.
    # 
    def save!
      save @path
    end
    
    #
    # Saves the current proeject at the specified path.
    # 
    # @note currently this does not support saving the workspaces associated 
    #   with the project to their new location.
    # 
    # @param [String] path the path to save the project
    #
    def save(path)
      Dir.mkdir(path) unless File.exists?(path)
      
      project_filepath = "#{path}/project.pbxproj"
      
      # @toodo Save the workspace when the project is saved
      # FileUtils.cp_r "#{path}/project.xcworkspace", "#{path}/project.xcworkspace"
      
      File.open(project_filepath,'w') do |file|
        
        # The Hash#to_xcplist saves a semi-colon at the end which needs to be removed
        # to ensure the project file can be opened.
        
        file.puts %{// !$*UTF8*$!"\n#{@registry.to_xcplist.gsub(/\};\s*\z/,'}')}}
        
      end
    end
    
    def scheme(name)
      scheme = @schemes.select {|t| t.name == name.to_s}.first
      raise "No such scheme #{name}, available schemes are #{@schemes.map {|t| t.name}.join(', ')}" if scheme.nil?
      yield scheme if block_given?
      scheme
    end
    
    def targets
      @project.targets.map do |target|
        target.project = self
        target
      end
    end
    
    def target(name)
      target = targets.select {|t| t.name == name.to_s}.first
      raise "No such target #{name}, available targets are #{targets.map {|t| t.name}.join(', ')}" if target.nil?
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
      shared_schemes = Dir["#{@path}/xcshareddata/xcschemes/*.xcscheme"]
      user_specific_schemes = Dir["#{@path}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
      
      (shared_schemes + user_specific_schemes).each do |scheme|
        @schemes << Xcode::Scheme.new(self, scheme)
      end
    end
  
    #
    # Using the sytem tool plutil, the specified project file is parsed and 
    # converted to JSON, which is then converted to a hash object.
    # 
    # This content contains all the data within the project file and is used
    # to create the Registry.
    # 
    # @return [Resource] a resource mapped to the root resource within the project
    #   this is generally the project file which contains details about the main
    #   group, targets, etc.
    # 
    # @see Registry
    # 
    def parse_pbxproj
      registry = JSON.parse(`plutil -convert json -o - "#{@path}/project.pbxproj"`)
      
      class << registry
        include Xcode::Registry
      end
      
      # @toodo this does not entirely make sense to set the instance variable 
      #   of the registry here and then return the root project. It should likely
      #   just return the registry.
      
      @registry = registry
      Xcode::Resource.new registry.root, registry
    end

  end
end
