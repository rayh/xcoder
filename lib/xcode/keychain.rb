module Xcode
  class Keychain
    def initialize(path)
      @path = File.expand_path path
    end
    
    def import(cert, password)
      cmd = []
      cmd << "security"
      cmd << "import '#{cert}'"
      cmd << "-k #{@path}"
      cmd << "-P #{password}"
      cmd << "-T /usr/bin/codesign"
      Xcode::Shell.execute(cmd)
    end
    
    def unlock(password)
      cmd = []
      cmd << "security"
      cmd << "unlock-keychain #{@path}"
      cmd << "-p #{password}"
      Xcode::Shell.execute(cmd)
    end
    
    def self.login_keychain
      Xcode::Keychain.new("~/Library/Keychains/login.keychain")
    end
  end
end