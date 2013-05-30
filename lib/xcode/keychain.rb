module Xcode
  
  module Keychains

    #
    # Yield when the keychain is in the search path and remove it when the block returns
    #
    def self.with_keychain_in_search_path(kc, &block)
      kc.in_search_path &block
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
      
      cmd = Xcode::Shell::Command.new "security"
      cmd << "list-keychain"
      cmd << "-s #{search_list.join(' ')}"
      cmd.execute
    end
  end
  
  class Keychain
    include Xcode::TerminalOutput

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

    def to_s
      "Keychain(#{@name})"
    end

    #
    # Installs this keychain in the head of teh search path and restores the original on
    # completion of the block
    #
    # @param the block to be invoked with the modified search path
    #
    def in_search_path(&block)
      keychains = Keychains.search_path
      begin 
        Keychains.search_path = [self] + keychains
        yield
      ensure
        Keychains.search_path = keychains
        # print_task 'keychain', "Restored search path"
      end
    end
    
    #
    # Import the .p12 certificate file into the keychain using the provided password
    # 
    # @param [String] the path to the .p12 certificate file
    # @param [String] the password to open the certificate file
    #
    def import(cert, password)
      cmd = Xcode::Shell::Command.new "security"
      cmd << "import '#{cert}'"
      cmd << "-k \"#{@path}\""
      cmd << "-P #{password}"
      cmd << "-T /usr/bin/codesign"
      cmd.execute
    end
    
    #
    # Returns a list of identities in the keychain. 
    # 
    # @return [Array<String>] a list of identity names
    #
    def identities
      names = []
      cmd = Xcode::Shell::Command.new "security"
      cmd << "find-certificate"
      cmd << "-a"
      cmd << "\"#{@path}\""
      cmd.show_output = false
      cmd.execute.join("").scan /\s+"labl"<blob>="([^"]+)"/ do |m|
        names << m[0]
      end
      names
    end
    
    #
    # Secure the keychain 
    #
    def lock
      cmd = Xcode::Shell::Command.new "security"
      cmd << "lock-keychain"
      cmd << "\"#{@path}\""
      cmd.execute
    end
    
    #
    # Unlock the keychain using the provided password
    # 
    # @param [String] the password to open the keychain
    #
    def unlock(password)
      cmd = Xcode::Shell::Command.new "security"
      cmd << "unlock-keychain"
      cmd << "-p #{password}"
      cmd << "\"#{@path}\""
      cmd.execute
    end
    
    #
    # Create a new keychain with the given name and password
    # 
    # @param [String] the name for the new keychain
    # @param [String] the password for the new keychain
    # @return [Xcode::Keychain] an object representing the new keychain
    #
    def self.create(path, password)
      cmd = Xcode::Shell::Command.new "security"
      cmd << "create-keychain"
      cmd << "-p #{password}"
      cmd << "\"#{path}\""
      cmd.execute
      
      cmd = Xcode::Shell::Command.new "security"
      cmd << "set-keychain-settings"
      cmd << "-u"
      cmd << "\"#{path}\""
      cmd.execute
      
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
      cmd = Xcode::Shell::Command.new "security"
      cmd << "delete-keychain \"#{@path}\""
      cmd.execute
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