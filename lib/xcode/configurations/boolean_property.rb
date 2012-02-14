

module BooleanProperty
  extend self
  
  def load(value)
    value.to_s =~ /^YES$/
  end
  
  def save(value)
    value ? "YES" : "NO"
  end
  
end