

module TargetedDeviceFamily
  extend self
  
  def open(value)
    value.split(",").map do |platform_number|
      platforms[platform_number]
    end
  end
  
  def save(value)
    Array(value).map do |platform_name|
      platforms.map {|number,name| number if name == platform_name }
    end.flatten.join(",")
  end
  
  private
  
  def platforms
    { 1 => 'iPhone', 2 => 'iPad' }
  end
  
end
