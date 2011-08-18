require 'find'
require 'fileutils'
require "xcode/version"
require "xcode/project"
require "xcode/build"
require "xcode/info_plist"

module Xcode
  @@projects = nil
  @@sdks = nil
  
  # def self.project(name)
  #   parse_projects if @@projects.nil?
  #   @@projects.each do |p|
  #     return p if p.name == name
  #   end
  #   raise "Unable to find project named #{name}"
  # end
  
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
