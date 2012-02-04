require 'xcode/builder'

module Xcode
  module Configuration
    
    attr_accessor :target
    
    def info_plist_location
      buildSettings['INFOPLIST_FILE']
    end
    
    def product_name
      substitute(buildSettings['PRODUCT_NAME'])
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
    
    def info_plist
      puts properties
      info = Xcode::InfoPlist.new(self, info_plist_location)
      yield info if block_given?
      info.save
      info
    end
    
    def builder
      puts "Making a Builder with #{self} #{self.methods}"
      Xcode::Builder.new(self)
    end
    
  end
end