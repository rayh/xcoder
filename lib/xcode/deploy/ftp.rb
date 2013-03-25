require 'net/ftp'
require 'xcode/deploy/web_assets'

module Xcode
  module Deploy
    class Ftp
      attr_accessor :host, :username, :password, :dir

      def initialize(builder, options = {})
        @builder = builder
        @username = options[:username]
        @password = options[:password]
        @dir = options[:dir]
        @host = options[:host]
        @base_url = options[:base_url]
      end

      # Support templating of member data.
      def get_binding
        binding
      end

      def remote_installation_path
        File.join(@dir, @builder.product_name)
      end

      def deploy
        WebAssets.generate @builder, @base_url do |dir|
          puts "Connecting to #{@remote_host} with username #{@username}"
          Net::FTP.open(@host, @username, @password) do |ftp|
            begin
              puts "Creating folder #{remote_installation_path}"
              ftp.mkdir(remote_installation_path)
            rescue Net::FTPError
              puts "It looks like the folder is already there."
            end

            puts "Changing to remote folder #{remote_installation_path}"
            files = ftp.chdir(remote_installation_path)

            Dir["#{dir}/*"].each do |f|
              filename = File.basename(f)
              puts "Uploading #{filename}"
              ftp.putbinaryfile(f, filename, 1024)
            end

            filename = File.basename("#{@builder.ipa_path}")
            puts "Uploading #{filename}"
            ftp.putbinaryfile("#{@builder.ipa_path}", filename, 1024)
          end
        end
      end

    end
  end
end
