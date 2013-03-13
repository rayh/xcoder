require 'nokogiri'

module Xcode

  # Schemes are an XML file that describe build, test, launch and profile actions
  # For the purposes of Xcoder, we want to be able to build and test
  class Scheme
    attr_reader :parent, :path, :name, :build_targets
    attr_accessor :build_config

    #
    # Parse all the schemes given the current project.
    #
    def self.find_in_project(project)
      find_in_path(project, project.path)
    end

    #
    # Parse all the schemes given the current workspace.
    #
    def self.find_in_workspace(workspace)
      schemes = find_in_path(workspace, workspace.path)

      # Project level schemes
      workspace.projects.each do |project|
        schemes+=find_in_path(workspace, project.path)
      end

      schemes
    end

    # Parse all the scheme files that can be found at the given path. Schemes
    # can be defined as `shared` schemes and then `user` specific schemes. Parsing
    # the schemes will load the shared ones and then the current acting user's
    # schemes.
    #
    #
    # @param project or workspace in which the scheme is contained
    # @return [Array<Scheme>] the shared schemes and user specific schemes found
    #   within the project/workspace at the path defined for schemes.
    #
    def self.find_in_path(parent, path)
      all_schemes_paths(path).map do |scheme_path|
        Xcode::Scheme.new(parent: parent, root: path, path: scheme_path)
      end
    end

    def initialize(params={})
      @parent = params[:parent]
      @path = File.expand_path params[:path]
      @root = File.expand_path(File.join(params[:root],'..'))
      @name = File.basename(path).gsub(/\.xcscheme$/,'')
      doc = Nokogiri::XML(open(@path))

      parse_build_actions(doc)
    end

    # Returns a builder for building this scheme
    def builder
      Xcode::Builder::SchemeBuilder.new(self)
    end

    def to_s
      "#{name} (Scheme) in #{parent}"
    end

    private

    #
    # @return an array of all the scheme filepaths found within the project
    # or workspace path provided.
    #
    def self.all_schemes_paths(path)
      shared_schemes_paths(path) + current_user_schemes_paths(path)
    end

    #
    # @return an array of all the shared scheme filespaths found within the
    # project or workspace path provided.
    #
    def self.shared_schemes_paths(root)
      Dir["#{root}/xcshareddata/xcschemes/*.xcscheme"]
    end

    #
    # @return an array of all the current user's scheme filespaths found within the
    # project or workspace path provided.
    #
    def self.current_user_schemes_paths(root)
      Dir["#{root}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
    end

    def target_from_build_reference(buildableReference)
      project_name  = buildableReference['ReferencedContainer'].gsub(/^container:/,'')
      target_name   = buildableReference['BlueprintName']
      project_path  = File.join @root, project_name
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
