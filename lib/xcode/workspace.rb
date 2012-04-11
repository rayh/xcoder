require 'xcode/project'
require 'nokogiri'

module Xcode
  class Workspace
    attr_reader :projects, :name, :path
    def initialize(path)
      path = "#{path}.xcworkspace" unless path=~/\.xcworkspace/
      path = "#{path}/contents.xcworkspacedata" unless path=~/xcworkspacedata$/
      
      @name = File.basename(path.gsub(/\.xcworkspace\/contents\.xcworkspacedata/,''))
      @projects = []
      @path = File.expand_path path
      
      doc = Nokogiri::XML(open(@path))
      doc.search("FileRef").each do |file|
        location = file["location"]
        if matcher = location.match(/^group:(.+)$/)
          project_path = "#{workspace_root}/#{matcher[1]}"
          @projects << Xcode::Project.new(project_path)
        end
      end
    end    
    
    def project(name)
      project = @projects.select {|c| c.name == name.to_s}.first
      raise "No such project #{name}, available projects are #{@projects.map {|c| c.name}.join(', ')}" if project.nil?
      yield project if block_given?
      project
    end
    
    def describe
      puts "Workspace #{name} contains:"
      projects.each do |p|
        p.describe
      end
    end
    
    def workspace_root
      File.dirname(File.dirname(@path))
    end
  end
end