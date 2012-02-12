module Xcode
  class Keychain
    attr_accessor :name, :path
    
    TEMP_PASSWORD = "build_keychain_password"
    def initialize(name)
      @name = name
      @path = File.expand_path "~/Library/Keychains/#{name}"
    end
    
    def import(cert, password)
      cmd = []
      cmd << "security"
      cmd << "import '#{cert}'"
      cmd << "-k '#{@path}'"
      cmd << "-P #{password}"
      cmd << "-T /usr/bin/codesign"
      Xcode::Shell.execute(cmd)
    end
    
    def certificates
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
    
    def unlock(password)
      cmd = []
      cmd << "security"
      cmd << "unlock-keychain"
      cmd << "-p #{password}"
      cmd << "#{@name}"
      Xcode::Shell.execute(cmd)
    end
    
    def self.create(name, password)
      cmd = []
      cmd << "security"
      cmd << "create-keychain"
      cmd << "-p #{password}"
      cmd << "#{name}"
      Xcode::Shell.execute(cmd)
      
      Xcode::Keychain.new(name)
    end
    
    # FIXME: dangerous
    def delete
      cmd = []
      cmd << "security"
      cmd << "delete-keychain #{name}"
      Xcode::Shell.execute(cmd)
    end
    
    def self.temp_keychain(name, &block)
      kc = Xcode::Keychain.create(name, TEMP_PASSWORD)
      begin
        kc.unlock(TEMP_PASSWORD)
        block.call(kc)
      ensure
        kc.delete
      end
    end
    
    def self.login_keychain
      Xcode::Keychain.new("login.keychain")
    end
  end
end