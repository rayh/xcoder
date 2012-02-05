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
  
  def self.projects
    @@projects = parse_projects if @@projects.nil?
    @@projects  
  end
  
  def self.workspaces
    @@workspaces = parse_workspaces if @@workspaces.nil?
    @@workspaces
  end
  
  def self.project(name)
    name = name.to_s
    
    return Xcode::Project.new(name) if name=~/\.xcodeproj/
    
    self.projects.each do |p|
      return p if p.name == name
    end
    raise "Unable to find a project named #{name}.  However, I did find these projects: #{self.projects.map {|p| p.name}.join(', ') }"
  end
  
  def self.workspace(name)
    name = name.to_s
    
    return Xcode::Workspace.new(name) if name=~/\.xcworkspace/
    
    self.workspaces.each do |p|
      return p if p.name == name
    end
    raise "Unable to find a workspace named #{name}.  However, I did find these workspaces: #{self.workspaces.map {|p| p.name}.join(', ') }"
  end
  
  def self.find_projects(dir='.')
    parse_projects(dir)
  end

  def self.is_sdk_available?(sdk)
    parse_sdks if @@sdks.nil?
    @@sdks.values.include? sdk
  end
  
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

class Hash
  def to_xcplist
    plist_of_items = map do |k,v| 
      suffix = ";" unless v.is_a?(Hash) or v.is_a?(Array)
      "\"#{k}\" = #{v.to_xcplist}#{suffix}"
    end.join("\n")
    
    %{{
      #{plist_of_items}
    };}
  end
end


class Array
  def to_xcplist
    plist_of_items = map {|item| item.to_xcplist }.join(",\n")
    
    %{(
      #{plist_of_items}
    );}
  end
end

class String
  def to_xcplist
    "\"#{to_s.gsub(/[^\\]"/,'\"')}\""
  end
end

class TrueClass
  def to_xcplist
    "YES"
  end
end

class FalseClass
  def to_xcplist
    "NO"
  end
end