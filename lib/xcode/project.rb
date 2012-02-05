require 'json'
require 'xcode/resource'
require 'xcode/target'
require 'xcode/configuration'
require 'xcode/scheme'
require 'xcode/group'
require 'xcode/file'

module Xcode
  class Project 
    attr_reader :name, :sdk, :path, :schemes
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @schemes = []
      @groups = []
      @name = File.basename(@path).gsub(/\.xcodeproj/,'')

      @project = parse_pbxproj
      parse_schemes
    end
    
    def groups
      @project.mainGroup
    end
    
    def save!
      save @path
    end
    
    def save(path)
      Dir.mkdir(path) unless File.exists?(path)
      
      project_filepath = "#{path}/project.pbxproj"
      
      # TODO: Save the workspace when the project is saved
      # FileUtils.cp_r "#{path}/project.xcworkspace", "#{path}/project.xcworkspace"
      
      File.open(project_filepath,'w') do |file|
        
        # The Hash#to_plist saves a semi-colon at the end which needs to be removed
        # to ensure the project file can be opened.
        
        file.puts %{// !$*UTF8*$!"\n#{@all_data.to_plist.gsub(/\};\s*\z/,'}')}}
        
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
      # schemes are in project/**/xcschemes/*.xcscheme
      Dir["#{@path}/**/xcschemes/*.xcscheme"].each do |scheme|
        @schemes << Xcode::Scheme.new(self, scheme)
      end
    end
  
    def parse_pbxproj
      json = JSON.parse(`plutil -convert json -o - "#{@path}/project.pbxproj"`)
      @all_data = json
      Xcode::Resource.new json['rootObject'], json
    end

  end
end
