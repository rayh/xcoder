

class TrueClass
  
  #
  # Xcode project's expect boolean trues to be the word YES.
  # 
  def to_xcplist
    "YES"
  end
end

class FalseClass
  
  #
  # Xcode project's expect boolean trues to be the word NO.
  # 
  def to_xcplist
    "NO"
  end
end