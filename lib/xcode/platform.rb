module Xcode
  
  module Platforms
    @@platforms = []
        
    def self.[] sdk_name
      supported.find {|p| p.sdk==sdk_name}
    end
    
    def self.find platform, version = nil
      platform = supported.sort do
        |a,b| a.version.to_f <=> b.version.to_f 
      end.find do |p| 
        p.platform==platform and (version.nil? or p.version==version)
      end
      
      raise "Unable to find a platform #{platform},#{version} - available platforms are #{supported.map{|p| p.sdk}.join(', ')}" if platform.nil?
      
      platform
    end

    def self.supported
      return @@platforms unless @@platforms.count==0
      
      parsing = false
      `xcodebuild -showsdks`.split("\n").each do |l|
        l.strip!
        if l=~/(.*)\s+SDKs:/
          parsing = true
        elsif l=~/^\s*$/
          parsing = false
        elsif parsing
          l=~/([^\t]+)\t+\-sdk (.*)/
          name = $1.strip
          $2.strip=~/([a-zA-Z]+)(\d+\.\d+)/

          platform = Platform.new name, $1, $2          
          @@platforms << platform
        end
      end
      
      @@platforms
    end
        
  end
  
  class Platform
    attr_reader :platform, :name, :version
    
    def initialize name, platform, version
      @platform = platform
      @name = name
      @version = version
    end
        
    def sdk
      "#{@platform}#{@version}"
    end
    
    def to_s
      "#{name} #{sdk}"
    end
  end
  
end