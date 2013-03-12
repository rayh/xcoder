require 'net/ssh'
require 'net/scp'
require 'xcode/deploy/web_assets'

module Xcode
  module Deploy
    class Ssh
      attr_accessor :host, :username, :password, :dir

      def initialize(builder, options)
        @builder = builder
        @username = @options[:username]
        @password = @options[:password]
        @dir = @options[:dir]
        @host = @options[:host]
        @base_url = @options[:base_url]
      end

      def remote_installation_path
        File.join(@dir, @builder.product_name)
      end

      def deploy
        WebAssets.generate @builder, @base_url do |dist_path|
          puts "Copying files to #{@remote_host}:#{remote_installation_path}"
          Net::SSH.start(@host, @username, :password => @password) do |ssh|
            puts "Creating folder with mkdir #{remote_installation_path}"
            ssh.exec!("mkdir #{remote_installation_path}")
          end
          Net::SCP.start(@host, @username, :password => @password) do |scp|
            puts "Copying files from folder #{dist_path}"
            Dir["#{dist_path}/*"].each do |f|
              puts "Copying #{f} to remote host in folder #{remote_installation_path}"
              scp.upload! "#{f}", "#{remote_installation_path}"
            end
            scp.upload! "#{@options[:ipa_path]}", "#{remote_installation_path}"
          end
        end
      end

    end
  end
end
