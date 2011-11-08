require 'xcode/shell'

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
    
    def builder
      Xcode::Builder.new(self)
    end
  end
end