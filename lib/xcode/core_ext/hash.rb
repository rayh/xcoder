class Hash
  
  # 
  # Hashes in an Xcode project take a particular format.
  # 
  # @note the keys are represeted in this output with quotes; this is actually
  #   optional for certain keys based on their format. This is done to ensure
  #   that all keys that do not conform are ensured proper output.
  # 
  # @example output format:
  # 
  #     {
  #       "KEY" = "VALUE";
  #       "KEY" = "VALUE";
  #       "KEY" = "VALUE";
  #     }
  # 
  def to_xcplist
    plist_of_items = map do |k,v| 
      "\"#{k}\" = #{v.to_xcplist};"
    end.join("\n")
    
    %{{
      #{plist_of_items}
    }}
  end
end