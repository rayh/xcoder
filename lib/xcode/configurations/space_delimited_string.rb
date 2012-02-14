

module SpaceDelimitedString
  extend self
  
  def open(value)
    value.split(" ")
  end
  
  def save(value)
    Array(value).join(" ")
  end
  
end
