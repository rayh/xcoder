module Xcode
  class Target
    attr_reader :configs, :project
    
    def initialize(project, json)
      @project = project
      @json = json
      @configs = {}
    end
    
    def productName
      @json['productName']
    end
    
    def name
      @json['name']
    end
    
    def config(name)
      config = @configs[name.to_s.to_sym]
      raise "No such config #{name}, available configs are #{@configs.keys}" if config.nil?
      yield config if block_given?
      config
    end
    
  end
  
end