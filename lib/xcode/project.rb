require 'xcode/parsers/plutil_project_parser'
require 'xcode/resource'
require 'xcode/registry'

module Xcode
  
  #
  # The project is the representation of an Xcode Project folder, the `*.xcodeproj`,
  # folder that contains a number of workspace files and project files like
  # `project.pbxproj`. 
  # 
  # The Project represents the top-most element within the structure. It contains 
  # most of the methods that allow you to traverse through the targets and
  # configurations that it is composed.
  # 
  class Project 
    
    # @return [String] the name of the project; This value is deteremined from the 
    #   first part of the Xcode project folder name (e.g. "TestProject.xcodeproj" 
    #   name is "TestProject")
    attr_reader :name
    
    # @return [String] the sdks for the project. This is specified during the project
    #   initialization. If none are provided this currently defaults to "iphoneos"
    attr_reader :sdk
    
    # @return [String] the expanded file path for the project. This is expanded from the
    #   file path specified during initialization.
    attr_reader :path
    
    # @return [Array<Scheme>] the schemes that are found within the project path.
    attr_reader :schemes
    
    # @return [Registry] the data that is parsed from the project.pbxproj, it is
    #   in most part a Hash with additional methods included to provide core
    #   functionality.
    attr_reader :registry
    
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
      @project = Xcode::Resource.new @registry.root, @registry
      
      @schemes = parse_schemes
    end
    
    
    #
    # @return [Fixnum] the project's object version
    # 
    def object_version
      @registry.object_version
    end

    #
    # @return [Fixnum] the project's archive version
    # 
    def archive_version
      @registry.archive_version
    end
    
    #
    # Returns the main group of the project where all the files reside.
    # 
    # @todo this really could use a better name then groups as it is the main group
    #   but it should likely be something like main_group, root or something
    #   else that conveys that this is the project root for files, and such.
    # 
    # @return [Group] the main group, the heart of the action of the file
    #   explorer for the Xcode project. From here all other groups and items
    #   may be found.
    # 
    def groups
      @project.main_group
    end
    
    #
    # Returns the group specified. If any part of the group does not exist along
    # the path the group is created. Also paths can be specified to make the 
    # traversing of the groups easier.
    # 
    # @note this will attempt to find the paths specified, if it fails to find them
    #   it will create one and then continue traversing.
    #
    # @example Traverse a path through the various sub-groups.
    # 
    #     project.group('Vendor/MyCode/Support Files')
    #     # is equivalent to ...
    #     project.group('Vendor').first.group('MyCode').first.group('Supporting Files')
    # 
    # @note this path functionality current is only exercised from the project level
    #   all groups will treat the path division `/` as simply a character.
    # 
    # @param [String] name the group name to find/create
    # 
    # @return [Group] the group with the specified name.
    # 
    def group(name,options = {},&block)
      # By default create missing groups along the way
      options = { :create => true }.merge(options)
      
      current_group = @project.main_group
      
      # @todo consider this traversing and find/create as a normal procedure when
      #   traversing the project.
      
      name.split("/").each do |path_component|
        found_group = current_group.group(path_component).first
        
        if options[:create] and found_group.nil?
          found_group = current_group.create_group(path_component)
        end
        
        current_group = found_group
        
        break unless current_group
      end
      
      current_group.instance_eval(&block) if block_given? and current_group
      
      current_group
    end
    
    #
    # Return the file that matches the specified path. This will traverse
    # the project's groups and find the file at the end of the path.
    #
    # @param [String] name_with_path the path to the file
    # @return [FileReference] the file that matches the name, nil if no file
    #   matches the path.
    def file(name_with_path)
      path, name = File.split(name_with_path)
      group(path).file(name).first
    end
    
    #
    # Most Xcode projects have a products group where products are placed. This 
    # will generate an exception if there is no products group.
    # 
    # @return [Group] the 'Products' group of the project.
    def products_group
      current_group = groups.group('Products').first
      
      current_group.instance_eval(&block) if block_given? and current_group
      
      current_group
    end
    
    #
    # Most Xcode projects have a Frameworks gorup where all the imported 
    # frameworks are shown. This will generate an exception if there is no
    # Frameworks group.
    # 
    # @return [Group] the 'Frameworks' group of the projet.
    def frameworks_group
      current_group = groups.group('Frameworks').first
      
      current_group.instance_eval(&block) if block_given? and current_group
      
      current_group
    end
    
    #
    # This will convert the current project file into a supported Xcode Plist 
    # format. This format is not json or a traditional plist so several core
    # Ruby objects gained the #to_xcplist method to save it properly.
    # 
    # Specifically this will add the necessary file header information and the 
    # surrounding mustache braces around the xcode plist format of the registry.
    # 
    # @return [String] Xcode Plist format of the project.
    def to_xcplist
      
      # @note The Hash#to_xcplist, which the Registry will save out as xcode,
      #   saves a semi-colon at the end which needs to be removed to ensure 
      #   the project file can be opened.
      
      %{// !$*UTF8*$!"\n#{@registry.to_xcplist.gsub(/\};\s*\z/,'}')}}
    end
    
    # 
    # Save the current project at the current path that it exists.
    # 
    def save!
      save @path
    end
    
    #
    # Saves the current project at the specified path.
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
        file.puts to_xcplist
      end
    end
    
    #
    # Return the scheme with the specified name. Raises an error if no schemes 
    # match the specified name.
    # 
    # @note if two schemes match names, the first matching scheme is returned.
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
    # @return [Array<Target>] an array of all the available targets for
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
    # @return [Target] the specific target that matches the name specified
    #
    def target(name)
      target = targets.select {|t| t.name == name.to_s}.first
      raise "No such target #{name}, available targets are #{targets.map {|t| t.name}.join(', ')}" if target.nil?
      yield target if block_given?
      target
    end
    
    #
    # Creates a new target within the Xcode project. This will by default not
    # generate all the additional build phases, configurations, and files
    # that create a project.
    # 
    # @todo generate a create target with sensible defaults, similar to how
    #   it is done through Xcode itself.
    # 
    # @todo based on the specified type of target, default build phases and
    #   configuration should be created for the target similar to what is 
    #   supported in xcode.  Currently even now the :ios target does not
    #   generate the deafult build_phases for you and requires you to make those.
    # 
    # @param [String] name the name to provide to the target. This will also
    #   be the value that other defaults will be based on.
    #
    # @return [Target] the target created.
    # 
    def create_target(name,type=:ios)
      
      target = @registry.add_object Target.send(type)
      @project.properties['targets'] << target.identifier
      
      target.name = name
      
      build_configuration_list = @registry.add_object(ConfigurationList.configration_list)
      target.build_configuration_list = build_configuration_list.identifier
      
      target.project = self
      
      yield target if block_given?
      
      target.save!
    end
    
    #
    # Remove a target from the Xcode project.
    # 
    # @note this will remove the first target that matches the specified name.
    # 
    # @note this will remove only the project entry at the moment and not the
    #   the files that may be associated with the target. All build phases, 
    #   build files, and configurations will automatically be cleaned up when
    #   Xcode is opened.
    # 
    # @param [String] name the name of the target to remove from the Xcode
    #   project.
    #
    # @return [Target] the target that has been removed.
    # 
    def remove_target(name)
      found_target = targets.find {|target| target.name == name }
      if found_target
        @project.properties['targets'].delete found_target.identifier
        @registry.remove_object found_target.identifier
      end
      found_target
    end
    
    # 
    # Prints to STDOUT a description of this project's targets, configuration and schemes.  
    #
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
    # @return [Array<Scheme>] the shared schemes and user specific schemes found
    #   within the projet at the path defined for schemes.
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
    # converted to JSON, which is then converted to a hash object. This content 
    # contains all the data within the project file and is used to create the 
    # Registry.
    # 
    # @return [Registry] the representation of the project, this is a Hash with
    #   additional methods to provide easier functionality.
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
