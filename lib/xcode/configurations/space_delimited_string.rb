

module SpaceDelimitedString
  extend self
  
  def open(value)
    value.to_s.split(" ")
  end
  
  def save(value)
    Array(value).join(" ")
  end
  
end
