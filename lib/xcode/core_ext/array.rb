class Array
  
  #
  # Arrays in an Xcode project take a particular format.
  # 
  # @note the last element in the array can have a comma; it is optional.
  # 
  # @example output format:
  # 
  #     (
  #       ITEM1,
  #       ITEM2,
  #       ITEM3
  #     )
  # 
  def to_xcplist
    plist_of_items = map {|item| item.to_xcplist }.join(",\n")
    
    %{(
      #{plist_of_items}
    )}
  end
end
