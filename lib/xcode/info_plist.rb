require 'plist'
require 'pp'

module Xcode
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

    def save
      File.open(@plist_location, 'w') {|f| f << @plist.to_plist}
    end
  end
end