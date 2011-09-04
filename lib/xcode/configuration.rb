module Xcode
  class Configuration
    attr_reader :target
    
    def initialize(target, json)
      @target = target
      @json = json
    end
    
    def substitute(value)
      if value=~/\$\(.*\)/
        value.gsub(/\$\((.*)\)/) do |match|
          case match
            when "$(TARGET_NAME)"
              @target.name 
            else
              raise "Unknown substitution variable #{match}"
          end
        end
      else
        value
      end
    end
    
    def info_plist_location
      @json['buildSettings']['INFOPLIST_FILE']
    end
    
    def product_name
      substitute(@json['buildSettings']['PRODUCT_NAME'])
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
      cmd << "xcodebuild"
      cmd << "-sdk #{@target.project.sdk}" unless @target.project.sdk.nil?
      cmd << "-project \"#{@target.project.path}\""
      cmd << "-target \"#{@target.name}\""
      cmd << "-configuration \"#{name}\""
      execute(cmd)
    end
    
    
    def sign(identity)
      cmd = []
      cmd << "codesign"
      cmd << "--force"
      cmd << "--sign \"#{identity}\""
      cmd << "--resource-rules=\"#{app_path}/ResourceRules.plist\""
      cmd << "--entitlements \"#{entitlements_path}\""
      cmd << "\"#{ipa_path}\""
      execute(cmd)
    end
    
    def entitlements_path
      "#{File.dirname(@target.project.path)}/build/#{@target.name}.build/#{name}-#{@target.project.sdk}/#{@target.name}.build/#{product_name}.xcent"
    end
    
    def app_path
      "#{File.dirname(@target.project.path)}/build/#{name}-#{@target.project.sdk}/#{product_name}.app"
    end

    def ipa_path
      "#{File.dirname(@target.project.path)}/build/#{name}-#{@target.project.sdk}/#{product_name}-#{name}-#{info_plist.version}.ipa"
    end

    def package(options={})
      cmd = []      
      cmd << "xcrun"
      cmd << "-sdk #{@target.project.sdk.nil? ? "iphoneos" : @target.project.sdk}"
      cmd << "PackageApplication"
      cmd << "-v \"#{app_path}\""
      cmd << "-o \"#{ipa_path}\""
      
      if options.has_key? :sign
        cmd << "--sign \"#{options[:sign]}\""
      end
      
      if options.has_key? :profile
        cmd << "--embed \"#{options[:profile]}\""
      end
      
      execute(cmd)
    end
    
    private 
    
    def execute(bits, show_output=true)
      out = []
      cmd = bits.join(' ')
      puts "EXECUTE: #{cmd}"
      IO.popen (cmd) do |f| 
        f.each do |line|
          puts line if show_output
          out << line
        end 
      end
      #puts "RETURN: #{out.inspect}"
      out
    end
    
  end
end