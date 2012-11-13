require 'nokogiri'

module Xcode

  # Schemes are an XML file that describe build, test, launch and profile actions
  # For the purposes of Xcoder, we want to be able to build and test
  # The scheme's build action only describes a target, so we need to look at launch for the config
  class Scheme

    #
    # Parse all the scheme files that can be found in the given project or workspace. Schemes
    # can be defined as `shared` schemes and then `user` specific schemes. Parsing
    # the schemes will load the shared ones and then the current acting user's
    # schemes.
    #
    # @return [Array<Scheme>] the shared schemes and user specific schemes found
    #   within the projet/workspace at the path defined for schemes.
    #
    def self.find_in_path(path)
      all_schemes_paths(path).map do |scheme_path|
        Xcode::Scheme.new(root: path, path: scheme_path)
      end
    end

    def self.find_in_project(project)
      find_in_path(project.path)
    end

    attr_reader :path, :name, :launch, :test

    def initialize(params={})
      @path = File.expand_path params[:path]
      @root = File.expand_path(File.join(params[:root],'..'))
      @name = File.basename(path).gsub(/\.xcscheme$/,'')
      doc = Nokogiri::XML(open(path))

      @launch = parse_action(doc, 'launch')
      @test = parse_action(doc, 'test')
    end

    def builder
      Xcode::Builder.new(self)
    end

    private

    def self.all_schemes_paths(path)
      shared_schemes_paths(path) + current_user_schemes_paths(path)
    end

    def self.shared_schemes_paths(root)
      Dir["#{root}/xcshareddata/xcschemes/*.xcscheme"]
    end

    def self.current_user_schemes_paths(root)
      Dir["#{root}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
    end

    def parse_action(doc, action_name)
      action = doc.xpath("//#{action_name.capitalize}Action").first
      buildableReference = action.xpath('BuildableProductRunnable/BuildableReference').first
      return nil if buildableReference.nil?

      project_name  = buildableReference['ReferencedContainer'].gsub(/^container:/,'')
      project       = Xcode.project File.join(@root,project_name)
      target_name   = buildableReference['BlueprintName']

      project.target(target_name).config(action['buildConfiguration'])
    end

  end
end