require 'erb'
require 'ostruct'

module Xcode
	module Deploy
		module WebAssets
			class BindingContext < OpenStruct
				def get_binding
    	    return binding()
		    end
			end

			def self.generate(builder, &block)
				Dir.mktmpdir do |dist_path|

					context = BindingContext.new
					context.product_name = builder.product_name
					context.manifest_url = "manifest.plist"
					context.deployment_url = builder.ipa_name
					context.bundle_version = builder.config.info_plist.version
					context.bundle_identifier = builder.config.info_plist.identifier

	        rhtml = ERB.new(File.read("#{File.dirname(__FILE__)}/templates/manifest.rhtml"))
	        File.open("#{dist_path}/manifest.plist", "w") do |io|
	          io.write(rhtml.result(context.get_binding))
	        end

	        rhtml = ERB.new(File.read("#{File.dirname(__FILE__)}/templates/index.rhtml"))
	        File.open("#{dist_path}/index.html", "w") do |io|
	          io.write(rhtml.result(context.get_binding))
	        end

	        yield dist_path
	      end
			end
		end
	end
end