require 'rake'
require 'rake/tasklib'

module Xcode
  def self.task(name, &block)
    t = TaskBuilder.new name
    t.instance_eval(&block)
    t.generate_rake_tasks
  end

  class TaskBuilder < ::Rake::TaskLib

    include ::Rake::DSL if defined?(::Rake::DSL)

    def initialize name
      @name = name
      @before = lambda {|builder| return nil }
      @deployments = []
      @profile = "Provisioning/#{name}.mobileprovision"
    end

    def use args={}
      @args = args
    end

    def before &block
      @before = block
    end

    def keychain path, password = nil
      @keychain = {:path => path, :password => password}
    end

    def profile profile
      @profile = profile
    end

    def deploy type, args = {}
      @deployments << {:type => type, :args => args}
    end

    def builder
      return @builder unless @builder.nil?

      if !@args[:project].nil?
        project = Xcode.project @args[:project]
        @builder = project.target(@args[:target]).config(@args[:config]).builder
      elsif !@args[:workspace].nil?
        workspace = Xcode.workspace @args[:workspace]
      else
        raise "You must provide a project or workspace"
      end

      raise "Could not create a builder using #{@args}" if @builder.nil?

      unless @keychain.nil?
        keychain = Xcode::Keychain.new @keychain[:path]
        keychain.unlock @keychain[:password] unless @keychain[:password].nil?

        builder.identity = keychain.identities.first
        builder.keychain = keychain
      end

      @before.call(builder)  

      @builder
    end

    def generate_rake_tasks
      require 'socket'

      namespace @name.downcase do 

        desc "Clean #{@name}"
        task :clean do
          builder.clean
        end

        desc "Build #{@name}"
        task :build => [:clean] do
          timestamp = Time.now.strftime("%Y%m%d%H%M%S")
          builder.config.info_plist do |info|
            info.version = ENV['BUILD_NUMBER']||"SNAPSHOT-#{Socket.gethostname}-#{timestamp}"
            info.save
          end
          builder.build
        end


        desc "Package (.ipa & .dSYM.zip) #{@name}"
        task :package => [:build] do
          builder.package
        end

        namespace :deploy do 
          @deployments.each do |deployment|          
            desc "Deploy #{@name} to #{deployment[:type]}"
            task deployment[:type]  => [:package] do
              builder.deploy deployment[:type], deployment[:args]
            end
          end

          desc "Deploy #{@name} to all"
          task :all  => [:package]+(@deployments.map{|k,v| k[:type]}) do
            puts "Deployed to all"
          end
        end
      end
    end
   
  end
end