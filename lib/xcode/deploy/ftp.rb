require 'net/ftp'
require 'net/ssh'
require 'net/scp'

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
      
      def deploy
        prepare
        #final_deploy
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
        File.open("#{@dist_path}/manifest.plist", "w") do |io|
          io << %{
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>items</key>
              <array>
                <dict>
                  <key>assets</key>
                  <array>
                    <dict>
                      <key>kind</key>
                      <string>software-package</string>
                      <key>url</key>
                      <string>#{deployment_url}</string>
                    </dict>
                  </array>
                  <key>metadata</key>
                  <dict>
                    <key>bundle-identifier</key>
                    <string>#{@options[:info_plist].identifier}</string>
                    <key>bundle-version</key>
                    <string>#{@options[:info_plist].version}</string>
                    <key>kind</key>
                    <string>software</string>
                    <key>title</key>
                    <string>#{@options[:product_name]}</string>
                  </dict>
                </dict>
              </array>
            </dict>
            </plist>
          }
        end
        File.open("#{@dist_path}/index.html", "w") do |io|
          io << %{
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
            <title>Beta Download</title>
            <style type="text/css">
            body {background:#fff;margin:0;padding:0;font-family:arial,helvetica,sans-serif;text-align:center;padding:10px;color:#333;font-size:16px;}
            #container {width:300px;margin:0 auto;}
            h1 {margin:0;padding:0;font-size:14px;}
            p {font-size:13px;}
            .link {background:#ecf5ff;border-top:1px solid #fff;border:1px solid #dfebf8;margin-top:.5em;padding:.3em;}
            .link a {text-decoration:none;font-size:15px;display:block;color:#069;}
            </style>
            </head>
            <body>
            <div id="container">
            <div class="link"><a href="itms-services://?action=download-manifest&url=#{manifest_url}">Tap Here to Install<br />#{@options[:product_name]}<br />On Your Device</a></div>
            <p><strong>Link didn't work?</strong><br />
            Make sure you're visiting this page on your device, not your computer.</p>
            </body>
            </html>
          }
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