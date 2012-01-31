module Xcode
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
     
     unless @values[:identity].nil?
       builder.identity = @values[:identity] 
       puts "[#{label}] Set build identity to #{@values[:identity]}"
     end
     
     unless @values[:profile].nil?
       builder.profile = @values[:profile]
       puts "[#{label}] Set build profile to #{@values[:profile]}"
     end
     
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
          
      
     if @values.has_key? :testflight_api_token and @values.has_key? :testflight_team_token
       puts "[#{label}] Uploading to testflight"
       `curl -X POST http://testflightapp.com/api/builds.json -F file=@"#{builder.ipa_path}" -F dsym=@"#{builder.dsym_zip_path}" -F api_token='#{@values[:testflight_api_token]}' -F team_token='#{@values[:testflight_team_token]}' -F notify=True -F notes=\"#{@values[:testflight_notes]}\" -F distribution_lists='#{@values[:testflight_lists].join(',')}'`
     end
     
     builder
   end
   
  end
end