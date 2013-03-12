require 'aws-sdk'
require 'xcode/deploy/web_assets'
module Xcode
  module Deploy
  	class S3
  		def initialize(builder, options)
  			@builder = builder
  			@options = options
  		end

  		def bucket
  			return @bucket unless @bucket.nil?
  			s3 = AWS::S3.new @options
	      @bucket = s3.buckets.create(options[:bucket]) rescue s3.buckets[options[:bucket]]
	      @bucket
			end

  		def deploy
  			WebAssets.generate @builder do |dir|
  				Dir["#{dir}/*"].each do |path|
  					puts "Uploading #{path} => #{bucket.name}/#{File.basename(path)}"
  					bucket["#{@options[:dir]||''}/#{File.basename(path)}"].
  						write(File.open(path), :acl => :public_read)
  				end
  			end
  		end
  	end
  end
end