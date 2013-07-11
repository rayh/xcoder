require 'xcode/project'
require 'nokogiri'

module Xcode
  class Workspace
    attr_reader :projects, :name, :path
    def initialize(path)
      path      = "#{path}.xcworkspace" unless path=~/\.xcworkspace/
      
      @name     = File.basename(path.gsub(/\.xcworkspace/,''))
      @projects = []
      @schemes  = nil
      @path     = File.expand_path path
      
      doc = Nokogiri::XML(open("#{@path}/contents.xcworkspacedata"))
      doc.search("FileRef").each do |file|
        location = file["location"]
        if (matcher = location.match(/^group:(.+\.xcodeproj)$/i))
          project_path = "#{workspace_root}/#{matcher[1]}"
          begin
            @projects << Xcode::Project.new(project_path)
          rescue => e
            puts "Skipping project file #{project_path} referened by #{self} as it failed to parse"
          end
        end
      end
    end    
    
    #
    # @return [Array<Xcode::Scheme>] available schemes for the workspace
    #
    def schemes
      return @schemes unless @schemes.nil?
      @schemes = Xcode::Scheme.find_in_workspace(self)
      @schemes
    end
    
    #
    # Return the scheme with the specified name. Raises an error if no schemes 
    # match the specified name.
    # 
    # @note if two schemes match names, the first matching scheme is returned.
    # 
    # @param [String] name of the specific scheme
    # @return [Scheme] the specific scheme that matches the name specified
    #
    def scheme(name)
      scheme = schemes.select {|t| t.name == name.to_s and t.parent == self}.first
      raise "No such scheme #{name} in #{self}, available schemes are #{schemes.map {|t| t.to_s}.join(', ')}" if scheme.nil?
      yield scheme if block_given?
      scheme
    end
    
    #
    # Return the names project.  Raises an error if no projects 
    # match the specified name.
    # 
    # @note if two projects match names, the first matching scheme is returned.
    # 
    # @param [String] name of the specific scheme
    # @return [Project] the specific project that matches the name specified
    #
    def project(name)
      project = @projects.select {|c| c.name == name.to_s}.first
      raise "No such project #{name} in #{self}, available projects are #{@projects.map {|c| c.name}.join(', ')}" if project.nil?
      yield project if block_given?
      project
    end

    def to_s
      "#{name} (Workspace)"
    end
    
    def describe
      puts "Workspace #{name} contains:"
      projects.each do |p|
        p.describe
      end
    end
    
    def workspace_root
      File.dirname(@path)
    end
  end
end