module Xcode
  class Build
    attr_accessor :project
    
    def initialize(project, target, config)
      @project = project
      @target = target.to_s
      @config = config.to_s
      
      raise "Target #{@target} is not valid, should be one of #{@project.targets}" unless @project.targets.include? @target
      raise "Configuration #{@config} is not valid, should be one of #{@project.configurations}" unless @project.configurations.include? @config
    end
    
    def build
      cmd = []
      cmd << "-target #{@target}"
      cmd << "-configuration #{@config}"
      @project.execute_xcodebuild(cmd.join(' '))
    end
    
    def app_path
      "#{File.dirname(@project.path)}/build/#{@config}-#{@project.sdk}/#{@target}.app"
    end

    def ipa_path
      "#{File.dirname(@project.path)}/build/#{@config}-#{@project.sdk}/#{@target}.ipa"
    end

    def package(options={})
      cmd = []
      cmd << "-v #{app_path}"
      cmd << "-o #{ipa_path}"
      
      if options.has_key? :certificate
        cmd << "--sign #{options[:certificate]}"
      end
      
      if options.has_key? :profile
        cmd << "--embed #{options[:profile]}"
      end
      
      @project.execute_package_application(cmd.join(' '))
    end
    
  end
end