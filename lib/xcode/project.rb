require 'xcode/parsers/plutil_project_parser'
require 'xcode/resource'
require 'xcode/target'
require 'xcode/configuration'
require 'xcode/scheme'
require 'xcode/group'
require 'xcode/file_reference'
require 'xcode/registry'
require 'xcode/build_phase'
require 'xcode/variant_group'
require 'xcode/configuration_list'

module Xcode
  class Project 
    
    attr_reader :name, :sdk, :path, :schemes, :registry
    
    #
    # Initialized with a specific path and sdk.
    # 
    # This initialization is not often used. Instead projects are generated
    # through the Xcode#project method.
    # 
    # @see Xcode
    #
    # @param [String] path of the project to open.
    # @param [String] sdk the sdk value of the project. This will default to 
    #   `iphoneos`.
    # 
    def initialize(path, sdk=nil)
      @sdk = sdk || "iphoneos"  # FIXME: should support OSX/simulator too
      @path = File.expand_path path
      @schemes = []
      @groups = []
      @name = File.basename(@path).gsub(/\.xcodeproj/,'')
      
      # Parse the Xcode project file and create the registry
      
      @registry = parse_pbxproj
      @project = Xcode::Resource.new registry.root, @registry
      
      @schemes = parse_schemes
    end
    
    #
    # Returns the main group of the project where all the files reside.
    # 
    # @return [PBXGroup]
    # @see PBXGroup
    # 
    def groups
      @project.mainGroup
    end
    
    # 
    # Save the current project at the current path that it exists.
    # 
    def save!
      save @path
    end
    
    #
    # Saves the current proeject at the specified path.
    # 
    # @note currently this does not support saving the workspaces associated 
    #   with the project to their new location.
    # 
    # @param [String] path the path to save the project
    #
    def save(path)
      Dir.mkdir(path) unless File.exists?(path)
      
      project_filepath = "#{path}/project.pbxproj"
      
      # @toodo Save the workspace when the project is saved
      # FileUtils.cp_r "#{path}/project.xcworkspace", "#{path}/project.xcworkspace"
      
      File.open(project_filepath,'w') do |file|
        
        # The Hash#to_xcplist saves a semi-colon at the end which needs to be removed
        # to ensure the project file can be opened.
        
        file.puts %{// !$*UTF8*$!"\n#{@registry.to_xcplist.gsub(/\};\s*\z/,'}')}}
        
      end
    end
    
    
    #
    # Return the scheme with the specified name. Raises an error if no schemes 
    # match the specified name.
    # 
    # @note if two schemes match names, the first matching scheme is return.
    # 
    # @param [String] name of the specific scheme
    # @return [Scheme] the specific scheme that matches the name specified
    #
    def scheme(name)
      scheme = @schemes.select {|t| t.name == name.to_s}.first
      raise "No such scheme #{name}, available schemes are #{@schemes.map {|t| t.name}.join(', ')}" if scheme.nil?
      yield scheme if block_given?
      scheme
    end
    
    #
    # All the targets specified within the project.
    # 
    # @return [Array<PBXNativeTarget>] an array of all the available targets for
    #   the specific project.
    # 
    def targets
      @project.targets.map do |target|
        target.project = self
        target
      end
    end
    
    #
    # Return the target with the specified name. Raises an error if no targets
    # match the specified name.
    # 
    # @note if two targets match names, the first matching target is returned.
    # 
    # @param [String] name of the specific target
    # @return [PBXNativeTarget] the specific target that matches the name specified
    #
    def target(name)
      target = targets.select {|t| t.name == name.to_s}.first
      raise "No such target #{name}, available targets are #{targets.map {|t| t.name}.join(', ')}" if target.nil?
      yield target if block_given?
      target
    end
    
    def create_target
      
      target_identifier = @registry.add_object(Target.target_for_type(:ios))
      target = @registry.object target_identifier
      @project.properties['targets'] << target_identifier
      
      yield target if block_given?
      
      # @todo if build phases have not been specified then assume we want to
      #   create all the default build phases. How would one specify that they
      #   want to not specify any build phases?
      
      # @todo if build configurations have not been specified then assume we 
      #   want to create all the default configrations. How would one specify 
      #   that they want to not specify any configurations? How do we figure
      #   out what are the default configurations?
      
      target.save!
      
      target
    end
    
    # def create_target(target_type)
    #   
    #   # Create the new target with the specific type
    #   
    #   target_identifier = @registry.add_object Target.target_for_type(target_type)
    #   @project.properties['targets'] << target_identifier
    #   
    #   new_target = @project.targets.last
    #   
    #   # Create the build phases for this particular target
    #   
    #   new_target.buildPhases = [
    #     @registry.add_object(BuildPhase.framework_build_phase),
    #     @registry.add_object(BuildPhase.sources_build_phase),
    #     @registry.add_object(BuildPhase.resources_build_phase)
    #   ]
    #   
    #   
    #   
    #   yield new_target if block_given?
    #   
    #   # Add a build configuration list with the build configurations
    #   
    #   build_config_list = ConfigurationList.configration_list do |list|
    #     
    #     list['buildConfigurations'] = [
    #       @registry.add_object(Configuration.default_properties(new_target.name,"Debug")),
    #       @registry.add_object(Configuration.default_properties(new_target.name,"Release"))
    #     ]
    #     list['defaultConfigurationName'] = 'Release'
    #     
    #   end
    #   
    #   new_target.buildConfigurationList = @registry.add_object build_config_list
    #   
    #   
    #   product_file = @registry.add_object FileReference.app_product(new_target.name)
    #   
    #   @project.mainGroup.group('Products').first.properties['children'] << product_file
    # 
    #   @registry.set_object(new_target)
    #   
    #   new_target
    #   
    # end
    
    def describe
      puts "Project #{name} contains"
      targets.each do |t|
        puts " + target:#{t.name}"
        t.configs.each do |c|
          puts "    + config:#{c.name}"
        end
      end
      schemes.each do |s|
        puts " + scheme #{s.name}"
        puts "    + Launch action => target:#{s.launch.target.name}, config:#{s.launch.name}" unless s.launch.nil?
        puts "    + Test action   => target:#{s.test.target.name}, config:#{s.test.name}" unless s.test.nil?
      end
    end
    
    private
  
    #
    # Parse all the scheme files that can be found within the project. Schemes
    # can be defined as `shared` schemes and then `user` specific schemes. Parsing
    # the schemes will load the shared ones and then the current acting user's
    # schemes.
    # 
    def parse_schemes
      shared_schemes = Dir["#{@path}/xcshareddata/xcschemes/*.xcscheme"]
      user_specific_schemes = Dir["#{@path}/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes/*.xcscheme"]
      
      (shared_schemes + user_specific_schemes).map do |scheme|
        Xcode::Scheme.new(self, scheme)
      end
    end
  
    #
    # Using the sytem tool plutil, the specified project file is parsed and 
    # converted to JSON, which is then converted to a hash object.
    # 
    # This content contains all the data within the project file and is used
    # to create the Registry.
    # 
    # @return [Resource] a resource mapped to the root resource within the project
    #   this is generally the project file which contains details about the main
    #   group, targets, etc.
    # 
    # @see Registry
    # 
    def parse_pbxproj
      
      registry = Xcode::PLUTILProjectParser.parse "#{@path}/project.pbxproj"
      
      class << registry
        include Xcode::Registry
      end
      
      registry
    end

  end
end
