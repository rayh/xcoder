module Xcode
  class Keychain
    attr_accessor :name, :path
    
    TEMP_PASSWORD = "build_keychain_password"
    
    #
    # Open the keychain with the specified name.  It is assumed that keychains reside in the 
    # ~/Library/Keychains directory
    # 
    # @param [String] the name of the keychain
    #
    def initialize(name)
      @name = name
      @path = File.expand_path "~/Library/Keychains/#{name}"
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
      cmd << "-k '#{@path}'"
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
      cmd << "#{@name}"
      data = Xcode::Shell.execute(cmd, false).join("")
      data.scan /\s+"labl"<blob>="([^"]+)"/ do |m|
        names << m[0]
      end
      names
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
      cmd << "#{@name}"
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Create a new keychain with the given name and password
    # 
    # @param [String] the name for the new keychain
    # @param [String] the password for the new keychain
    # @return [Xcode::Keychain] an object representing the new keychain
    #
    def self.create(name, password)
      cmd = []
      cmd << "security"
      cmd << "create-keychain"
      cmd << "-p #{password}"
      cmd << "#{name}"
      Xcode::Shell.execute(cmd)
      
      Xcode::Keychain.new(name)
    end
    
    #
    # Remove the keychain from the filesystem
    #
    # FIXME: dangerous
    #
    def delete
      cmd = []
      cmd << "security"
      cmd << "delete-keychain #{name}"
      Xcode::Shell.execute(cmd)
    end
    
    #
    # Creates a keychain with the given name that lasts for the duration of the provided block.  
    # The keychain is deleted even if the block throws an exception.
    # 
    # @param [String] the name of the temporary keychain to create
    #
    def self.temp_keychain(name, &block)
      kc = Xcode::Keychain.create(name, TEMP_PASSWORD)
      begin
        kc.unlock(TEMP_PASSWORD)
        block.call(kc)
      ensure
        kc.delete
      end
    end
    
    #
    # Opens the default login.keychain for current user
    # 
    # @return [Xcode::Keychain] the current user's login keychain
    #
    def self.login_keychain
      Xcode::Keychain.new("login.keychain")
    end
  end
end