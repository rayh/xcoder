require 'nokogiri'

module Xcode
  
  # Schemes are an XML file that describe build, test, launch and profile actions
  # For the purposes of Xcoder, we want to be able to build and test
  class Scheme
    attr_reader :parent, :path, :name, :build_config, :build_targets
    def initialize(parent, path)
      @parent = parent
      @path = File.expand_path(path)
      @root = File.expand_path "#{parent.path}/../"
      @name = File.basename(path).gsub(/\.xcscheme$/,'')
      doc = Nokogiri::XML(open(@path))      
      
      parse_build_actions(doc)
    end
    
    # Returns a builder for building this scheme
    def builder
      Xcode::Builder::SchemeBuilder.new(self)
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
    def self.find_in_path(path, parent)
      shared_schemes = Dir["#{path}/xcshareddata/xcschemes/*.xcscheme"]
      user_specific_schemes = Dir["#{path}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
      
      (shared_schemes + user_specific_schemes).map do |scheme|
        Xcode::Scheme.new(parent, scheme)
      end
    end
    
    private 
    
    def target_from_build_reference(buildableReference)
      project_name  = buildableReference['ReferencedContainer'].gsub(/^container:/,'')
      target_name   = buildableReference['BlueprintName']
      project_path  = "#{@root}/#{project_name}"  
      project       = Xcode.project project_path 
      project.target(target_name)
    end
    
    def parse_build_actions(doc)
      # Build Config
      @build_targets = []
      
      @build_config = doc.xpath("//LaunchAction").first['buildConfiguration']
      
      build_action_entries = doc.xpath("//BuildAction//BuildableReference").each do |ref|
        @build_targets << target_from_build_reference(ref) 
      end
      
    end

  end
end