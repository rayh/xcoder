require 'find'
require 'fileutils'
require "xcode/version"
require "xcode/project"
require "xcode/info_plist"
require "xcode/shell"
require 'plist'
require 'xcode/keychain'
require 'xcode/workspace'
require 'xcode/buildfile'

module Xcode
  
  @@projects = nil
  @@workspaces = nil
  @@sdks = nil
  
  #
  # Find all the projects within the current working directory.
  # 
  # @return [Array<Project>] an array of the all the Projects found.
  # 
  def self.projects
    @@projects = parse_projects if @@projects.nil?
    @@projects  
  end
  
  #
  # Find all the workspaces within the current working directory.
  # 
  # @return [Array<Workspaces>] an array of all the Workspaces found.
  # 
  def self.workspaces
    @@workspaces = parse_workspaces if @@workspaces.nil?
    @@workspaces
  end
  
  #
  # Find the project with the specified name within the current working directory.
  # 
  # @note this method will raise an error when it is unable to find the project
  #   specified.
  # 
  # @param [String] name of the project (e.g. NAME.xcodeproj) that is attempting
  #   to be found.
  # 
  # @return [Project] the project found; an error is raise if a project is unable
  #   to be found.
  # 
  def self.project(name)
    name = name.to_s
    
    return Xcode::Project.new(name) if name=~/\.xcodeproj/
    
    self.projects.each do |p|
      return p if p.name == name
    end
    raise "Unable to find a project named #{name}.  However, I did find these projects: #{self.projects.map {|p| p.name}.join(', ') }"
  end
  
  #
  # Find the workspace with the specified name within the current working directory.
  # 
  # @note this method will raise an error when it is unable to find the workspace
  #   specified.
  # 
  # @param [String] name of the workspace (e.g. NAME.xcworkspace) that is attempting
  #   to be found.
  # 
  # @return [Project] the workspace found; an error is raise if a workspace is unable
  #   to be found.
  # 
  def self.workspace(name)
    name = name.to_s
    
    return Xcode::Workspace.new(name) if name=~/\.xcworkspace/
    
    self.workspaces.each do |p|
      return p if p.name == name
    end
    raise "Unable to find a workspace named #{name}.  However, I did find these workspaces: #{self.workspaces.map {|p| p.name}.join(', ') }"
  end
  
  #
  # @param [String] dir the path to search for projects; defaults to using
  #   the current working directory.
  # 
  # @return [Array<Project>] the projects found at the specified directory.
  #
  def self.find_projects(dir='.')
    parse_projects(dir)
  end

  #
  # @param [String] sdk name of the sdk that is being asked to see if available.
  # @return [TrueClass,FalseClass] true if the sdk is available; false otherwise.
  #
  def self.is_sdk_available?(sdk)
    parse_sdks if @@sdks.nil?
    @@sdks.values.include? sdk
  end
  
  #
  # Available SDKs available on this particular system.
  # 
  # @return [Array<String>] the available SDKs on the current system.
  # 
  def self.available_sdks
    parse_sdks if @@sdks.nil?
    @@sdks
  end
 
  private
  def self.parse_sdks
    @@sdks = {}
    parsing = false
    `xcodebuild -showsdks`.split("\n").each do |l|
      l.strip!
      if l=~/(.*)\s+SDKs:/
        parsing = true
      elsif l=~/^\s*$/
        parsing = false
      elsif parsing
        l=~/([^\t]+)\t+\-sdk (.*)/
        @@sdks[$1.strip] = $2.strip unless $1.nil? and $2.nil?
      end
    end
  end
  
  def self.parse_workspaces(dir='.')
    projects = []
    Find.find(dir) do |path|
      if path=~/\.xcworkspace$/ and !(path=~/\.xcodeproj\//)
        projects << Xcode::Workspace.new(path)
      end
    end
    projects
  end

  def self.parse_projects(dir='.')
    projects = []
    Find.find(dir) do |path|
      if path=~/(.*)\.xcodeproj$/
        projects << Xcode::Project.new(path)
      end
    end
    projects
  end
end

require 'xcode/core_ext/hash'
require 'xcode/core_ext/array'
require 'xcode/core_ext/string'
require 'xcode/core_ext/boolean'
require 'xcode/core_ext/fixnum'
