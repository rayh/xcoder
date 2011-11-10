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

	builder.package
	
This will produce a .ipa and a .dSYM.zip

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

There is basic support for schemes, you can access them from a project like so:

	config = project.scheme('MyScheme').launch   # Gets the Launch action for specified scheme.  
												 # Can also specify 'test' to get the test action

The 'launch' and 'test' methods access the different actions within the scheme, and they map to a Xcode::Configuration object (i.e., the schemes map to a target and configuration in a traditional XCode3 project style). 