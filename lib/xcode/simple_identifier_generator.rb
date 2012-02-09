module SimpleIdentifierGenerator
  extend self
  
  #
  # Generate an identifier string
  # 
  # @example identifier string
  # 
  #     "E21EB9EE14E359840058122A"
  # 
  # @return [String] a 24-length string that contains only hexadecimal characters.
  # 
  def generate
    range = ('A'..'F').to_a + (0..9).to_a
    24.times.inject("") {|ident| "#{ident}#{range.sample}" }
  end
end