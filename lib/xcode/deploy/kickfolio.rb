module Xcode
	module Deploy
		class Kickfolio

			def initialize(bundler, options={})
				@bundler = bundler
				@options = options
			end

			def deploy
				RestClient.post "https://kickfolio.com/api/apps/#{@options[:app_id]}", 
					{:bundle_url => @options[:url], :auth_token => @options[:api_key]},
					:content_type => 'application/json'
			end

		end
	end
end