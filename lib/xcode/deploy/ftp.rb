require 'net/ftp'
require 'erb'

module Xcode
  module Deploy
    class Ftp
      attr_accessor :remote_host, :deploy_to, :username, :password, :remote_directory
      #attr_accessor :product_name, :ipa_name, :dist_path, :ipa_path
      #attr_accessor :dsym_zip_path, :app_path, :configuration_build_path, :info_plist
      attr_accessor :options
      
      def initialize(options)
        @options=options
      end
      
      # Support templating of member data.
      def get_binding
        binding
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
          puts "Connecting to #{@remote_host} with username #{@username}"
          Net::FTP.open(@remote_host, @username, @password) do |ftp|
            begin
              puts "Creating folder #{remote_installation_path}"
              ftp.mkdir(remote_installation_path)
            rescue Net::FTPError
              puts "It looks like the folder is already there."
            end
            puts "Changing to remote folder #{remote_installation_path}"
            files = ftp.chdir(remote_installation_path)
            Dir["#{@dist_path}/*"].each do |f|
              filename = File.basename(f)
              puts "Uploading #{filename}"
              ftp.putbinaryfile(f, filename, 1024)
            end
            filename = File.basename("#{@options[:ipa_path]}")
            puts "Uploading #{filename}"
            ftp.putbinaryfile("#{@options[:ipa_path]}", filename, 1024)
          end
      end
      
    end
  end
end