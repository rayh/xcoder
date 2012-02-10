# XCoder

A ruby wrapper around various xcode tools and the project.pbxproj

## Example Usage

You will need to install the gem:

	gem install xcoder

and then require the gem in your project/rakefile/etc

	require 'xcoder'
	
### Load a project

    project = Xcode.project('MyProject')  # Can be the name, the file (e.g. MyProject.xcodeproj) or the path

### Finding all projects from the current directory down

	Xcode.find_projects.each {|p| puts p.name }
	
### Find a configuration for a target on a project

	config = Xcode.project(:MyProject).target(:Target).config(:Debug)	# returns an Xcode::Configuration object

### Building a configuration

	builder = config.builder
	builder.profile = 'Profiles/MyAdHoc.mobileprovision'	# This will remove old profiles and install the profile
	builder.identity = 'iPhone Developer: Ray Hilton'		# The name of the identity to use to sign the IPA (optional)
	builder.build
	
### Packaging a built .app

After performing the above build, you can create a versioned, well named .ipa and .dSYM.zip

	builder.package
	
This will produce something like: MyProject-Debug-1.0.ipa and MyProject-Debug-1.0.dSYM.zip

### Incrementing the build number

	config.info_plist do |info|
	  info.version = info.version.to_i + 1
	  info.save
	end

### Working with workspaces

Loading workspaces can be done in a similar way to projects:

	Xcode.workspaces.each do |w|
	  w.describe								# prints a recursive description of the 
												# structure of the workspace and its projects
	end
	
Or, if you know the name:

	workspace = Xcode.workspace('MyWorkspace')  # Can be the name, the file (e.g. MyWorkspace.xcworkspace) or the path
	
	
### Schemes

There is basic support for schemes, you can enumerate them from a project like so:

	project.schemes.each do |s|
	  s.builder.build
	end
	
Or, access them by name:

	builder = project.scheme('MyScheme').builder
	
Note: The builder behaves the same as the builder for the target/config approach and will force xcodebuild to use the local build/ directory (as per xcode3) rather than a generated temporary directory in DerivedData.  This may or may not be a good thing.

Note: Shared schemes and user (current logged in user) specific schemes are both loaded. They may share names and other similarities that make them hard to distinguish. Currently the priority loading order is shared schemes and then user specific schemes.

### Provisioning profiles

The library provides a mechanism to install/uninstall a provisioning profile.  This normally happens as part of a build (if a profile is provided to the builder, see above), but you can do this manually:

	Xcode::ProvisioningProfile.new("Myprofile.mobileprovision").install	# installs profile into ~/Library
	
Or enumerate installed profiles:
   
	Xcode::ProvisioningProfile.installed_profiles.each do |p|
		p.uninstall		# Removes the profile from ~/Library/
	end

### Security / Keychain

The missing component here is to be able to manipulate keychains.  This is quite possible through the command line 'security' tool, but will probably only be necessary once per project, and so I have no plans to support this.  If you can think of a use-case, please raise and issue for it!

### Testflight

The common output of this build/package process is to upload to testflight.  This is pretty simple with xcoder:

	builder.upload(API_TOKEN, TEAM_TOKEN) do |tf|
	  tf.notes = "some release notes"
 	  tf.notify = true	# Whether to send a notification to users, default is true
      tf.lists << "AList"  # The lists to distribute the build to
	end
	
You can also optionally set a .proxy= property or just set the HTTP_PROXY environment variable.

### OCUnit to JUnit 

You can invoke your test target/bundle from the builder

	builder.test do |report|
		report.write 'test-reports', :junit
	end
	
This will invoke the test target, capture the output and write the junit reports to the test-reports directory.  Currently only junit is supported.

## Tests

There are some basic RSpec tests in the project which I suspect /wont/ work on machines without my identity installed.  

Currently these tests only assert the basic project file parsing and build code and do not perform file modification tests (e.g. for info plists) or provisioning profile/keychain importing
	
## Feedback

Please raise issues if you find defects or have a feature request.  