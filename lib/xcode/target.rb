module Xcode
  class Target
    attr_reader :configs, :project
    
    def initialize(project, json)
      @project = project
      @json = json
      @configs = []
    end
    
    def productName
      @json['productName']
    end
    
    def name
      @json['name']
    end
    
    def config(name)
      config = @configs.select {|c| c.name == name.to_s}.first
      raise "No such config #{name}, available configs are #{@configs.map {|c| c.name}.join(', ')}" if config.nil?
      yield config if block_given?
      config
    end
    
  end
  
end