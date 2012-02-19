module SimpleIdentifierGenerator
  extend self
  
  MAX_IDENTIFIER_GENERATION_ATTEMPTS = 10
  
  #
  # Generate an identifier string
  # 
  # @example generating a new identifier
  # 
  #     SimpleIdentifierGenerator.generate # => "E21EB9EE14E359840058122A"
  # 
  # @example generating a new idenitier ensuring it does not match existing keys
  # 
  #     SimpleIdentifierGenerator.generate :existing_keys => [ "E21EB9EE14E359840058122A" ] # => "2574D65B0D2FFDB5D0372B4A"
  # 
  # @param [Hash] options contains any additional parameters; namely the 
  #   `:existing_keys` parameters which will help ensure uniqueness.
  # 
  # @return [String] a 24-length string that contains only hexadecimal characters.
  # 
  def generate(options = {})
    
    existing_keys = options[:existing_keys] || []
    
    # Ensure that the identifier generated is unique
    identifier_generation_count = 0
    
    new_identifier = generate_new_key
    
    while existing_keys.include?(new_identifier)
      
      new_identifier = generate_new_key
      
      # Increment our identifier generation count and if we reach our max raise
      # an exception as something has gone horribly wrong.

      identifier_generation_count += 1
      if identifier_generation_count > MAX_IDENTIFIER_GENERATION_ATTEMPTS
        raise "SimpleIdentifierGenerator is unable to generate a unique identifier"
      end
    end
    
    new_identifier
    
  end
  
  private
  
  #
  # Generates a new identifier string
  # 
  # @example identifier string
  # 
  #     "E21EB9EE14E359840058122A"
  # 
  # @return [String] a new identifier string
  # 
  def generate_new_key
    range = ('A'..'F').to_a + (0..9).to_a
    24.times.inject("") {|ident| "#{ident}#{range.sample}" }
  end
  
end