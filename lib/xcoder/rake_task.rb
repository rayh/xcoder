require 'xcoder'
require 'rake'
require 'rake/tasklib'


module Xcode
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    # The name of the prefixed namespace. By default this will by 'xcode'
    attr_accessor :name
    
    #
    # @param [String,Array<String>] project_names names of the project and projects
    #   that are found in the specified directory. 
    #
    def projects=(project_names)
      @projects = Xcode.find_projects(directory).find_all{|project| Array(project_names).include? project.name }
    end
    
    #
    # @return [Array<Projects>] all the projects found that match the filtering
    #   criteria at the specified directory or all projects at the specified 
    #   directory.
    # 
    def projects
      @projects ||= Xcode.find_projects(directory)
    end

    #
    # @param [String] value file path to search for Xcode projects. Xcoder attempts
    #   to find all the projects recursively from this specified path.
    #
    def directory=(value)
      @directory = File.expand_path(value)
    end
    
    #
    # The default directory is the current working directory. This can be
    # overriden to search for projects within a specified folder path.
    # 
    def directory
      @directory ||= File.expand_path('.')
    end
    
    #
    # @todo this should likely be generated from the Xcode::Builder object/class
    #   itself
    # 
    # @return [Array] available actions of a Builder
    def builder_actions
      [ :build, :test, :clean, :package ]
    end
    
    #
    # By default this will generate rake tasks within the 'xcode' namespace for
    # all the projects (within the current working directory), all their targets, 
    # and all their configs. This will also generate tasks for all of a projects
    # schemes as well.
    # 
    # @example
    # 
    #       rake xcode:hackbook:hackbook:debug:build   
    #       rake xcode:hackbook:hackbook:debug:clean         
    #       rake xcode:hackbook:hackbook:debug:package       
    #       rake xcode:hackbook:hackbook:debug:test          
    #       rake xcode:hackbook:hackbook:release:build       
    #       rake xcode:hackbook:hackbook:release:clean       
    #       rake xcode:hackbook:hackbook:release:package     
    #       rake xcode:hackbook:hackbook:release:test        
    # 
    # The task accepts a single parameter. This parameter allows you to change
    # the root namespace that the tasks are generated within.
    # 
    # @example
    # 
    #     Xcode::RakeTask.new :apple
    # 
    #     rake apple:hackbook:hackbook:debug:build
    #     # ...
    # 
    # Additionally a block can be specified to provide additional configuration:
    # 
    # @example specifying a directory parameter to search within a different folder
    #
    #     Xcode::RakeTask.new :apple do |xcoder|
    #       xcoder.directory = "~/dayjobprojects"
    #     end
    #     
    #     rake apple:dayjobproject1:moneytarget:debug:build
    #     # ...
    # 
    # Often you do not want to generate rake tasks for all the projects. So you
    # can specify the names of the projects you do want to have appear.
    # 
    # @example specifying projects to filter on by the name of a project
    #
    #     Xcode::RakeTask.new :apple do |xcoder|
    #       xcoder.directory = "~/dayjobprojects"
    #       xcoder.projects = "Dayjobproject2"
    #     end
    #     
    #     rake apple:dayjobproject2:socialtarget:debug:build
    #     # ...
    # 
    #
    def initialize(name = :xcode)
      
      @name = name
      
      yield self if block_given?
      
      define_all_projects_list_task
      define_project_list_tasks
      define_per_project_scheme_builder_tasks
      define_per_project_config_builder_tasks

    end
    
    private
    
    def define_all_projects_list_task
      desc "List details for all the projects"
      task "#{name}:list" do
        projects.each {|project| project.describe }
      end
    end
    
    def define_project_list_tasks
      projects.each do |project|
        desc "List details for all the projects"
        task "#{name}:#{friendlyname(project.name)}:list" do
          project.describe
        end
      end
    end
    
    #
    # Generate all the Builder Tasks for all the matrix of all the Projects and
    # Schemes
    # 
    def define_per_project_scheme_builder_tasks
      
      projects.each do |project|
        project.schemes.each do |scheme|
          builder_actions.each do |action|
            
            description = "#{action.capitalize} #{project.name} #{scheme.name}"
            task_name = friendlyname("#{name}:#{project.name}:scheme:#{scheme.name}:#{action}")
            
            define_task_with description, task_name do
              scheme.builder.send(action)
            end
            
          end
        end
      end
      
    end

    #
    # Generate all the Builder Tasks for all the matrix of all the Projects,
    # Targets, and Configs
    # 
    def define_per_project_config_builder_tasks
      
      projects.each do |project|
        project.targets.each do |target|
          target.configs.each do |config|
            
            builder_actions.each do |action|
              
              description = "#{action.capitalize} #{project.name} #{target.name} #{config.name}"
              task_name = friendlyname("#{name}:#{project.name}:#{target.name}:#{config.name}:#{action}")
            
              define_task_with description, task_name do
                config.builder.send(action)
              end
              
            end
            
          end
        end
      end
      
      
    end
    
    
    #
    # @param [String] description the task decription
    # @param [String] task_name the name of the task with namespace
    #
    def define_task_with(description,task_name,&block)
      
      desc description
      task task_name do
        block.call
      end
      
    end
    
    
    # 
    # @param [String,Symbol] name to convert that may contain camel-casing and
    #   spacing.
    # 
    # @return [String] a name which is all lower-cased, spaces are replaced with
    #   underscores.
    #
    def friendlyname(name)
      name.underscore.gsub(/\s/,'-')
    end
    
    
  end

end
