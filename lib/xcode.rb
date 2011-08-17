require 'find'
require 'fileutils'
require "xcode/version"
require "xcode/project"

module Xcode
  @@projects = nil
  @@sdks = nil
  
  def self.project(name)
    parse_projects if @@projects.nil?
    @@projects.each do |p|
      return p if p.name == name
    end
    raise "Unable to find project named #{name}"
  end
  
  def self.projects
    parse_projects if @@projects.nil?
    @@projects
  end

  def self.is_sdk_available?(sdk)
    parse_sdks if @@sdks.nil?
    @@sdks.values.include? sdk
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

  def self.parse_projects
    @@projects = []
    Find.find('.') do |path|
      if path=~/(.*)\.scaffold$/
        @@projects << LocalScaffold.new(path)
      end
    end
  end
end
