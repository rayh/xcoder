require 'json'

class String
  
  #
  # Xcode format for a string is exactly the same as you would expect in JSON
  # 
  def to_xcplist
    to_json
  end
  
  #
  # Similar to ActiveRecord's underscore method. Return a string version 
  # underscored. This is used specifically to convert the property keys into
  # Ruby friendly names as they are used for creating method names.
  # 
  # @return [String] convert camel-cased words, generating underscored, ruby
  #   friend names.
  def underscore
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end
