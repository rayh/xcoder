module Xcode
  class ProvisioningProfile
    include Xcode::TerminalOutput
    attr_reader :path, :name, :uuid, :identifiers, :devices, :appstore
    def initialize(path)
      
      raise "Provisioning profile '#{path}' does not exist" unless File.exists? path
      
      @path = path
      @identifiers = []
      @devices = []
      @appstore = true
      @enterprise = false
      
      # TODO: im sure this could be done in a nicer way.  maybe read out the XML-like stuff and use the plist -> json converter
      uuid = nil
      File.open(path, "rb") do |f|
        input = f.read
        
        if input=~/ProvisionedDevices/
          @appstore = false
        end
        
        if input=~/<key>ProvisionsAllDevices<\/key>/
          @enterprise = true
        end
        
        if input=~/<key>ProvisionedDevices<\/key>.*?<array>(.*?)<\/array>/im
          $1.split(/<string>/).each do |id|
            next if id.nil? or id.strip==""
            @devices << id.gsub(/<\/string>/,'').strip
          end
        end
        
        input=~/<key>UUID<\/key>.*?<string>(.*?)<\/string>/im
        @uuid = $1.strip
                
        input=~/<key>Name<\/key>.*?<string>(.*?)<\/string>/im
        @name = $1.strip
        
        input=~/<key>ApplicationIdentifierPrefix<\/key>.*?<array>(.*?)<\/array>/im
        $1.split(/<string>/).each do |id|
          next if id.nil? or id.strip==""
          @identifiers << id.gsub(/<\/string>/,'').strip
        end
      end
    
    end
    
    def appstore?
      @appstore
    end
    
    def enterprise?
      @enterprise
    end

    def self.profiles_path
      File.expand_path "~/Library/MobileDevice/Provisioning\\ Profiles/"  
    end
    
    def install_path
      "#{ProvisioningProfile.profiles_path}/#{self.uuid}.mobileprovision"
    end
    
    def install
      # Do not reinstall if profile is same and is already installed
      return if (self.path == self.install_path.gsub(/\\ /, ' '))
      
      ProvisioningProfile.installed_profiles.each do |installed|
        if installed.identifiers==self.identifiers and installed.uuid==self.uuid
          installed.uninstall
        end
      end

      # print_task "profile", "installing #{self.path} with uuid #{self.uuid}", :info
      cmd = Xcode::Shell::Command.new 'cp'
      cmd << "\"" +self.path + "\""
      cmd << self.install_path
      cmd.execute
    end
    
    def uninstall
      # print_task "profile", "removing #{self.install_path}", :info
      cmd = Xcode::Shell::Command.new 'rm'
      cmd << "-f #{self.install_path}"
      cmd.execute
    end

    def self.installed_profiles
      Dir["#{self.profiles_path}/*.mobileprovision"].map do |file|
        ProvisioningProfile.new(file)
      end
    end

    def self.find_installed_by_uuid uuid
      ProvisioningProfile.installed_profiles.each do |p|
        return p if p.uuid == uuid
      end
    end

    def self.installed_profile(name)
      self.installed_profiles.select {|p| p.name == name.to_s}.first;
    end
    
  end
end