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
          builder.config.info_plist do |info|
            info.version = ENV['BUILD_NUMBER']||"#{Socket.gethostname}-SNAPSHOT"
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

  class Buildfile
   
   def initialize
     @values = {}
     @before = {:clean => [], :build => [], :package => []}
     @after = {:clean => [], :build => [], :package => []}
   end
   
   def method_missing(method, *args)
     @values[method.to_sym] = args[0]
   end
   
   def before(event, &block)
     @before[event]<< block
   end
   
   def after(event, &block)
     @after[event]<< block
   end
   
   def getBinding
     binding()
   end
   
   def self.load(file)
     file = File.expand_path file
     raise "Unable to find the buildfile #{file}" if !File.exists? file
     
     
     puts "Loading Buildfile: #{file}"
     bc = Xcode::Buildfile.new
     eval(File.read(file), bc.getBinding, file)
     bc
   end
   
   def build
     label = "#{@values[:target]}"
     puts "[#{label}] Loading project #{@values[:project]}, target #{@values[:target]}, config #{@values[:config]}"
     config = Xcode.project(@values[:project]).target(@values[:target]).config(@values[:config])
     config.info_plist do |info|
       puts "[#{label}] Update info plist version to #{@values[:version]}"
       info.version = @values[:version]
     end
     builder = config.builder
     
     # unless @values[:identity].nil?
     #   builder.identity = @values[:identity] 
     #   puts "[#{label}] Set build identity to #{@values[:identity]}"
     # end
     
     unless @values[:profile].nil?
       builder.profile = @values[:profile]
       puts "[#{label}] Set build profile to #{@values[:profile]}"
     end
     
     Keychain.temp do |kc|
       kc.import @values[:certificate], @values[:password]
       
       builder.identity = @values[:identity] || kc.identities.first
       builder.keychain = kc
       
       puts "[#{label}] CLEAN"
       @before[:clean].each do |b|
         b.call(builder)
       end
       builder.clean
       @after[:clean].each do |b|
         b.call(builder)
       end
     
       puts "[#{label}] BUILD"
       @before[:build].each do |b|
         b.call(builder)
       end
       builder.build
       @after[:build].each do |b|
         b.call(builder)
       end
     
       puts "[#{label}] PACKAGE"
       @before[:package].each do |b|
         b.call(builder)
       end
       builder.package
       @after[:package].each do |b|
         b.call(builder)
       end
     end
          
      
     if @values.has_key? :testflight_api_token and @values.has_key? :testflight_team_token
       puts "[#{label}] Uploading to testflight"
       `curl -X POST http://testflightapp.com/api/builds.json -F file=@"#{builder.ipa_path}" -F dsym=@"#{builder.dsym_zip_path}" -F api_token='#{@values[:testflight_api_token]}' -F team_token='#{@values[:testflight_team_token]}' -F notify=True -F notes=\"#{@values[:testflight_notes]}\" -F distribution_lists='#{@values[:testflight_lists].join(',')}'`
     end
     
     builder
   end
   
  end
end