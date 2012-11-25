require 'nokogiri'

module Xcode
  
  # Schemes are an XML file that describe build, test, launch and profile actions
  # For the purposes of Xcoder, we want to be able to build and test
  # The scheme's build action only describes a target, so we need to look at launch for the config
  class ProjectScheme
    attr_reader :path, :name, :launch, :test, :project
    def initialize(project, path)
      @project = project
      @path = File.expand_path(path)
      @root = File.expand_path "#{@path}/../../../../"
      @name = File.basename(path).gsub(/\.xcscheme$/,'')
      doc = Nokogiri::XML(open(@path))
      
      @launch = parse_action(doc, 'launch')
      @test = parse_action(doc, 'test')
    end
    
    # def project
    #   launch.target.project
    # end
    
    def builder
      Xcode::Builder::ProjectSchemeBuilder.new(scheme)
    end
    
    #
    # Parse all the scheme files that can be found in the given project or workspace. Schemes
    # can be defined as `shared` schemes and then `user` specific schemes. Parsing
    # the schemes will load the shared ones and then the current acting user's
    # schemes.
    # 
    # @param project the containing project
    # @return [Array<Scheme>] the shared schemes and user specific schemes found
    #   within the projet/workspace at the path defined for schemes.
    #
    def self.find_in_path(project, path)
      shared_schemes = Dir["#{path}/xcshareddata/xcschemes/*.xcscheme"]
      user_specific_schemes = Dir["#{path}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
      
      (shared_schemes + user_specific_schemes).map do |scheme|
        Xcode::ProjectScheme.new(project, scheme)
      end
    end
    
    private 
    
    def parse_action(doc, action_name)
      action = doc.xpath("//#{action_name.capitalize}Action").first
      buildableReference = action.xpath('BuildableProductRunnable/BuildableReference').first
      return nil if buildableReference.nil?
      
      project_name  = buildableReference['ReferencedContainer'].gsub(/^container:/,'')
      project       = Xcode.project "#{@root}/#{project_name}"    
      target_name   = buildableReference['BlueprintName']
      
      project.target(target_name).config(action['buildConfiguration'])
    end

  end
end