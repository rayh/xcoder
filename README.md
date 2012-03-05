# XCoder

Taking the pain out of scripting and automating xcode builds.

Xcoder is a ruby wrapper around various Xcode tools as well as providing project and workspace parsing and partial write support.  Xcoder also supports manipulation of keychains, packaging and uploading artifacts to [Testflight](http://testflightapp.com) and provisioning profile management.

Full documentation can be found here: http://rayh.github.com/xcoder/

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
	
### Working with Keychains
	
You will not normally need to worry about manipulating keychains unless you want to automate importing of certificates (in a CI system with many clients) or opening of specific keychains for different builds (the old two-certs-with-same-identity-name workaround).

You can either use the user's login keychain, another named keychain, or simply use a temporary keychain that will be blown away after the build.

#### Creating a temporary keychain

	Xcode::Keychain.temp do |keychain|
		# import certs into the keychain
		# perform builds within this keychain's context
	end	# Keychain is deleted
		
#### Importing a certificate

You can import a certificate from a .p12 file into a keychain.  Here we simply create a temporary keychain, import a certificate, set the identity onto the builder and then perform a build.
 
	keychain.import 'Certs/MyCert.p12', 'mycertpassword'		
	builder.keychain = keychain						# Tell the builder to use the temp keychain
	builder.identity = keychain.identities.first	# Get the first (only) identity name from the keychain
	
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

### [Testflight](http://testflightapp.com)

The common output of this build/package process is to upload to Testflight.  This is pretty simple with Xcoder:

	builder.testflight(API_TOKEN, TEAM_TOKEN) do |tf|
	  tf.notes = "some release notes"
 	  tf.notify = true	# Whether to send a notification to users, default is true
      tf.lists << "AList"  # The lists to distribute the build to
	end
	
You can also optionally set a .proxy= property or just set the HTTP_PROXY environment variable.

### OCUnit to JUnit reports

You can invoke your test target/bundle from the builder

	builder.test do |report|
		report.debug = false	# default false, set to true to see raw output from xcodebuild
		
		# The following is the default setup, you wouldnt normally need to do this unless
		# you want to add new formatters
		report.formatters = []
		report.add_formatter :junit, 'test-reports'	# Output JUnit format results to test-reports/
		report.add_formatter :stdout				# Output a simplified output to STDOUT
	end
	
This will invoke the test target, capture the output and write the junit reports to the test-reports directory.  Currently only junit is supported, although you can write your own formatter quite easily (for an example, look at Xcode::Test::Formatters::JunitFormatter).

## Rake Tasks

Xcoder provides a rake task to assist with make it easier to perform common Xcode project actions from the command-line.

Within your `Rakefile` add the following:

    require 'xcoder/rake_task'
    
Then define your Rake Task:

    Xcode::RakeTask.new

By default this will generate rake tasks within the 'xcode' namespace for
all the projects (within the current working directory), all their targets, 
and all their configs. This will also generate tasks for all of a projects
schemes as well.

    All names from the project, schemes, targets, and configs are remove
    the camel-casing and replacing the cameling with underscores. Spaces
    are replaced with dashes (-)

This will generate rake tasks that appear similar to the following:

      rake xcode:project-name:targetname:debug:build   
      rake xcode:project-name:targetname:debug:clean         
      # ...

You can specify a parameter to change the root rake namespace:

     Xcode::RakeTask.new :apple
     
     # Resulting Rake Tasks:
     # rake apple:project-name:targetname:debug:build
     # rake apple:project-name:targetname:debug:clean
     # ...

You can also supply a block to provide additional configuration to specify the folder to search for projects and the projects that should generate tasks for:

     Xcode::RakeTask.new :hudson do |xcoder|
       xcoder.directory = "projects"
       xcoder.projects = [ "Project Alpha", "Project Beta" ]
     end
     
     rake hudson:project-alpha:targetname:debug:build
     # ...

## [Guard](https://github.com/guard/guard)

Guard provides the ability to launch commands when files changed. There is a [guard-xcoder](https://github.com/burtlo/guard-xcoder) which allows you easily execute build actions whenever your project file changes.

    gem install guard
    gem install guard-xcoder
    
    guard init
    guard init xcoder

Afterwards you will need to define the project you want to monitor and the actions that you want to take place when a source files changes within the project file.

    guard 'xcoder', :actions => [ :clean, :build, :test ] do
      watch('ProjectName')
      watch('ProjectName//TargetName')
    end

## Manipulating a Project

Xcoder can also create targets, configurations, and add files. Xcoder could be used to programmatically manipulate or install external sources into a project.

It is important to note that Xcode gets cranky when the Xcode project file is changed by external sources. This usually causes the project and schemes to reset or maybe even cause Xcode to crash. It is often best to close the project before manipulating it with Xcoder.

### Add the source and header file to the project

    # Copy the physical source files into the project path `Vendor/Reachability`
    FileUtils.cp_r "examples/Reachability/Vendor", "spec/TestProject"
    
    source_files = [ { 'name' => 'Reachability.m', 'path' => 'Vendor/Reachability/Reachability.m' },
                     { 'name' => 'Reachability.h', 'path' => 'Vendor/Reachability/Reachability.h' } ]


     # Create and traverse to the group Reachability within the Vendor folder
     project.group('Vendor/Reachability') do
       # Create files for each source file defined above
       source_files.each |source| create_file source }
     end
     

Within the project file the groups in the path are created or found and then file references are added for the two specified source files. Xcoder only updates the logical project file, it does not copy physical files, that is done by the FileUtils.


### Adding source file to the sources build phase

    source_file = project.file('Vendor/Reachability/Reachability.m')

    # Select the main target of the project and add the source file to the build phase.

    project.target('TestProject').sources_build_phase do
      add_build_file source_file
    end

Adding source files does not automatically include it in any of the built targets. That is done after you add the source file to the `sources_build_phase`. First we find the source file reference, select our target and then add it as a build file.

### Adding a System Framework

    cfnetwork_framework = project.frameworks_group.create_system_framework 'CFNetwork'

    project.target('TestProject').framework_build_phase do
      add_build_file cfnetwork_framework
    end 
    
The **CFNetwork.framework** is added to the `Frameworks` group of the project and then added to the frameworks build phase.

### Saving your changes!


    project.save!

The saved file output is ugly compared to what you may normally see when you view a Xcode project file. Luckily, Xcode will fix the format of the file if you make any small changes to the project that require it to save.

### More Examples

Within the `specs/integration` folder there are more examples.

## Tests

There are some basic RSpec tests in the project which I suspect /wont/ work on machines without my identity installed.  

Currently these tests only assert the basic project file parsing and build code and do not perform file modification tests (e.g. for info plists) or provisioning profile/keychain importing
	
## Feedback

Please raise issues if you find defects or have a feature request.  
