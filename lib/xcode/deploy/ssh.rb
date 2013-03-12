require 'net/ssh'
require 'net/scp'

module Xcode
  module Deploy
    class Ssh
      attr_accessor :protocol, :remote_host, :deploy_to, :username, :password, :remote_directory
      attr_accessor :options
    
      def initialize(options)
        @options = options
      end
      
      def deploy
        prepare
        final_deploy
      end
      
      def deployment_url
        File.join(@deploy_to, @options[:product_name].downcase, @options[:ipa_name])
      end

      def manifest_url
        File.join(@deploy_to, @options[:product_name].downcase, "manifest.plist")
      end

      def remote_installation_path
        File.join(@remote_directory, @options[:product_name].downcase)
      end
      
      def prepare
        @dist_path = "#{@options[:configuration_build_path]}/dist"
        Dir.mkdir(@dist_path) unless File.exists?(@dist_path)
        
        spec = Gem::Specification.find_by_name("xcoder")
        gem_root = spec.gem_dir
        gem_lib = gem_root + "/lib"

        rhtml = ERB.new(File.read(gem_lib+"/xcode/deploy/templates/manifest.rhtml"))
        File.open("#{@dist_path}/manifest.plist", "w") do |io|
          io.write(rhtml.result(get_binding))
        end        
        
        rhtml = ERB.new(File.read(gem_lib+"/xcode/deploy/templates/index.rhtml"))
        File.open("#{@dist_path}/index.html", "w") do |io|
          io.write(rhtml.result(get_binding))
        end        
      end
      
      def final_deploy
          puts "Copying files to #{@remote_host}:#{remote_installation_path}"
          #system("scp #{@dist_path}/* #{@remote_host}:#{remote_installation_path}")
          Net::SSH.start(@remote_host, @username, :password => @password) do |ssh|
            puts "Creating folder with mkdir #{remote_installation_path}"
            ssh.exec!("mkdir #{remote_installation_path}")
          end
          Net::SCP.start(@remote_host, @username, :password => @password) do |scp|
            puts "Copying files from folder #{@dist_path}"
            Dir["#{@dist_path}/*"].each do |f|
              puts "Copying #{f} to remote host in folder #{remote_installation_path}"
              scp.upload! "#{f}", "#{remote_installation_path}"
            end
            scp.upload! "#{@options[:ipa_path]}", "#{remote_installation_path}"
          end
      end
      
    end
  end
end