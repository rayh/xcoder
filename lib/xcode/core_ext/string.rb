require 'json'

class String
  
  #
  # Xcode format for a string is exactly the same as you would expect in JSON
  # 
  def to_xcplist
    to_json
  end
end
