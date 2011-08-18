module Xcode
  class Configuration
    attr_reader :target
    
    def initialize(target, json)
      @target = target
      @json = json
    end
    
    def info_plist_location
      @json['buildSettings']['INFOPLIST_FILE']
    end
    
    def name
      @json['name']
    end
    
    def info_plist
      puts @json.inspect
      info = Xcode::InfoPlist.new(self, info_plist_location)  
      yield info if block_given?
      info
    end
    
    def build
      cmd = []
      cmd << "-target #{@target.name}"
      cmd << "-configuration #{name}"
      @target.project.execute_xcodebuild(cmd.join(' '))
    end
    
    def app_path
      "#{File.dirname(@target.project.path)}/build/#{name}-#{@target.project.sdk}/#{@target.productName}.app"
    end

    def ipa_path
      "#{File.dirname(@target.project.path)}/build/#{name}-#{@target.project.sdk}/#{@target.productName}.ipa"
    end

    def package(options={})
      cmd = []
      cmd << "-v #{app_path}"
      cmd << "-o #{ipa_path}"
      
      if options.has_key? :certificate
        cmd << "--sign #{options[:certificate]}"
      end
      
      if options.has_key? :profile
        cmd << "--embed #{options[:profile]}"
      end
      
      @target.project.execute_package_application(cmd.join(' '))
    end
  end
end