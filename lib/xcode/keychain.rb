module Xcode
  
  module Keychains
    
    #
    # Yield when the keychain is in the search path and remove it when the block returns
    #
    def self.with_keychain_in_search_path(kc, &block)
      keychains = self.search_path
      begin 
        self.search_path = [kc] + keychains
        yield
      ensure
        self.search_path = keychains
      end
    end
    
    
    #
    # Get the list of search keychains
    #
    # @return [Array<Xcode::Keychain>] the array of keychains the system currently searches
    #
    def self.search_path
      `security list-keychain`.split.map do |keychain| 
        Xcode::Keychain.new keychain.strip.gsub(/\"/,'')
      end
    end
    
    #
    # Set the keychains search path and order
    #
    # @param [Array<Xcode::Keychain>] the array of keychains for the system to search when signing
    #
    def self.search_path=(keychains)
      search_list = keychains.map do |kc|
        "\"#{kc.path}\""
      end
      
      cmd = []
      cmd << "security"
      cmd << "list-keychain"
      cmd << "-s #{search_list.join(' ')}"
      Xcode::Shell.execute(cmd)
    end
  end
  
  class Keychain
    attr_accessor :name, :path
    
    TEMP_PASSWORD = "build_keychain_password"
    
    #
    # Open the keychain with the specified name.  It is assumed that keychains reside in the 
    # ~/Library/Keychains directory
    # 
    # @param [String] the name of the keychain
    #
    def initialize(path)
      @path = File.expand_path path
      @name = File.basename path
      
      yield(self) if block_given?
    end
    
    #
    # Import the .p12 certificate file into the keychain using the provided password
    # 
    # @param [String] the path to the .p12 certificate file
    # @param [String] the password to open the certificate file
    #
    def import(cert, password)
      cmd = []
      cmd << "security"
      cmd << "import '#{cert}'"
      cmd << "-k \"#{@path}\""
      cmd << "-P #{password}"
      cmd << "-T /usr/bin/codesign"
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Returns a list of identities in the keychain. 
    # 
    # @return [Array<String>] a list of identity names
    #
    def identities
      names = []
      cmd = []
      cmd << "security"
      cmd << "find-certificate"
      cmd << "-a"
      cmd << "\"#{@path}\""
      data = Xcode::Shell.execute(cmd, false).join("")
      data.scan /\s+"labl"<blob>="([^"]+)"/ do |m|
        names << m[0]
      end
      names
    end
    
    #
    # Secure the keychain 
    #
    def lock
      cmd = []
      cmd << "security"
      cmd << "lock-keychain"
      cmd << "\"#{@path}\""
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Unlock the keychain using the provided password
    # 
    # @param [String] the password to open the keychain
    #
    def unlock(password)
      cmd = []
      cmd << "security"
      cmd << "unlock-keychain"
      cmd << "-p #{password}"
      cmd << "\"#{@path}\""
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Create a new keychain with the given name and password
    # 
    # @param [String] the name for the new keychain
    # @param [String] the password for the new keychain
    # @return [Xcode::Keychain] an object representing the new keychain
    #
    def self.create(path, password)
      cmd = []
      cmd << "security"
      cmd << "create-keychain"
      cmd << "-p #{password}"
      cmd << "\"#{path}\""
      Xcode::Shell.execute(cmd)
      
      kc = Xcode::Keychain.new(path)
      yield(kc) if block_given?
      kc
    end
    
    #
    # Remove the keychain from the filesystem
    #
    # FIXME: dangerous
    #
    def delete
      cmd = []
      cmd << "security"
      cmd << "delete-keychain \"#{@path}\""
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Creates a keychain with the given name that lasts for the duration of the provided block.  
    # The keychain is deleted even if the block throws an exception.
    #
    # If no block is provided, the temporary keychain is returned and it is deleted on system exit
    #
    def self.temp
      kc = Xcode::Keychain.create("/tmp/xcoder#{Time.now.to_i}", TEMP_PASSWORD)
      kc.unlock(TEMP_PASSWORD)
      
      if !block_given?
        at_exit do
          kc.delete
        end
        kc
      else
        begin
          yield(kc)
        ensure
          kc.delete
        end
      end
    end
    
    #
    # Opens the default login.keychain for current user
    # 
    # @return [Xcode::Keychain] the current user's login keychain
    #
    def self.login
      kc = Xcode::Keychain.new("~/Library/Keychains/login.keychain")
      yield(kc) if block_given?
      kc
    end
    
  end
end