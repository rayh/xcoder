# XCoder

A ruby wrapper around various xcode tools and the project.pbxproj

## Example Usage

You will need to install the gem:

	gem install xcoder

and then require the gem in your project/rakefile/etc

	require 'xcoder'
	
### Finding all projects from the current directory down

	Xcode.find_projects.each {|p| puts p.name }
	
### Find a configuration for a target on a project

	project = Xcode.find_projects.first
	config = project.target(:Target).config(:Debug)


### Building a configuration

	config.build
	
### Packaging a built .app

	config.package :sign => 'Developer Identity Name', :profile => 'Profile.mobileprovision'
	
### Incrementing the build number

	config.info_plist do |info|
	  info.version = info.version.to_i + 1
	  info.save
	end