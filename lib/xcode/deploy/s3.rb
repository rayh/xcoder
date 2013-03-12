require 'xcode/deploy/web_assets'
require 'aws-sdk'

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
	      @bucket = s3.buckets.create(@options[:bucket]) rescue s3.buckets[@options[:bucket]]
	      @bucket
			end

			def upload(path)
				obj_path = File.join(@options[:dir]||'', File.basename(path))
				puts "Uploading #{path} => #{bucket.name}/#{obj_path}"
				bucket.objects[obj_path].
					write(File.open(path), :acl => :public_read)
			end

  		def deploy
  			WebAssets.generate @builder do |dir|
  				Dir["#{dir}/*"].each do |path|
  					upload path
  				end

  				upload @builder.ipa_path
  			end
  		end
  	end
  end
end