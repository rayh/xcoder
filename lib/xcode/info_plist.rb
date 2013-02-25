require 'plist'
require 'pp'

module Xcode
  
  #
  # @see https://developer.apple.com/library/ios/#documentation/general/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html
  # 
  class InfoPlist
    def initialize(config, plist_location)
      @config = config
      
      @plist_location = File.expand_path("#{File.dirname(@config.target.project.path)}/#{plist_location}")
      unless File.exists?(@plist_location)
        puts 'Plist not found ' + @plist_location
        exit 1
      end
      @plist = Plist::parse_xml(@plist_location)
    end

    def marketing_version
      @plist['CFBundleShortVersionString']
    end

    def marketing_version=(version)
      @plist['CFBundleShortVersionString'] = version
    end

    def version
      @plist['CFBundleVersion']
    end

    def version=(version)
      @plist['CFBundleVersion'] = version.to_s
    end

    def identifier
      @plist['CFBundleIdentifier']
    end

    def identifier=(identifier)
      @plist['CFBundleIdentifier'] = identifier
    end

    def display_name
      @plist['CFBundleDisplayName']
    end

    def display_name=(name)
      @plist['CFBundleDisplayName'] = name
    end

    def save
      File.open(@plist_location, 'w') {|f| f << @plist.to_plist}
    end
    
    def increment_build(old_version)
      if (old_version.index(".") != nil) then # dot numbered version
        parts = old_version.split(".")
        last_part = parts.last.to_i
        last_part = last_part + 1
        parts.delete(parts.last)
        parts.insert(-1, last_part)
        new_version = parts.join(".")
      else # single integer version
        new_version = old_version.to_i + 1
      end
      return new_version
    end
    
  end
end