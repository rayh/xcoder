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
  end
end