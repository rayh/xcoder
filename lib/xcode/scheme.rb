require 'nokogiri'

module Xcode
  
  # Schemes are an XML file that describe build, test, launch and profile actions
  # For the purposes of Xcoder, we want to be able to build and test
  # The scheme's build action only describes a target, so we need to look at launch for the config
  class Scheme
    attr_reader :project, :path, :name, :launch, :test
    def initialize(project, path)
      @project = project
      @path = File.expand_path(path)
      @name = File.basename(path).gsub(/\.xcscheme$/,'')
      doc = Nokogiri::XML(open(@path))
      
      @launch = parse_action(doc, 'launch')
      @test = parse_action(doc, 'test')
    end
    
    
    private 
    
    def parse_action(doc, action_name)
      action = doc.xpath("//#{action_name.capitalize}Action").first
      buildableReference = action.xpath('BuildableProductRunnable/BuildableReference').first
      return nil if buildableReference.nil?
      
      target_name = buildableReference['BlueprintName']
      @project.target(target_name).config(action['buildConfiguration'])
    end

  end
end