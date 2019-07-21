# XCoder

## No Longer Maintained

Unfortuantely, I just don't have the time to maintain Xcoder, and given there are so many other tools that do bits and peices of what xcoder does, it doesnt feel as needed any more.

Perhaps parts of xcoder (keychain, profile management) could be extracted into stand-along tools - take a more unix-y approach to managing tools.

If anyone wants to more actively maintain Xcoder, please contact me.  

## Description 

Taking the pain out of scripting and automating xcode builds.

Xcoder is a ruby wrapper around various Xcode tools as well as providing project and workspace parsing and partial write support.  Xcoder also supports manipulation of keychains, packaging and uploading artifacts to [Testflight](http://testflightapp.com) and provisioning profile management.

Full documentation can be found here: http://rayh.github.com/xcoder/

## Requirements

Xcoder assumes you are using XCode 4.6 on Mountain Lion and ruby 1.9.  You may have some degree of success with lesser versions, but they are not intentionally supported.

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

	config = Xcode.project(:MyProject).target(:Target).config(:Debug)
	builder = config.builder
	builder.profile = 'Profiles/MyAdHoc.mobileprovision'	# This will remove old profiles and install the profile
	builder.identity = 'iPhone Developer: Ray Hilton'		# The name of the identity to use to sign the IPA (optional)
	builder.clean
	builder.build
	# Building uses the targets's default sdk, which you can override:
	builder.build :sdk => :iphonesimulator

### Working with Keychains

You will not normally need to worry about manipulating keychains unless you want to automate importing of certificates (in a CI system with many clients) or opening of specific keychains for different builds (the old two-certs-with-same-identity-name workaround).

You can either use the user's login keychain, another named keychain, or simply use a temporary keychain that will be blown away after the build.

#### Creating a temporary keychain

	Xcode::Keychain.temp do |keychain|
		# import certs into the keychain
		# perform builds within this keychain's context
	end	# Keychain is deleted

Or, you can create a temporary keychain that will be deleted when the process exits:

	keychain = Xcode::Keychain.temp


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

### Managing build numbers more efficiently

Based on our experience we suggest [Versionomy](https://github.com/dazuma/versionomy) to manage version numbers.
Although the marketing version is usually set by hand on release,
there are situations where it could be nice to have an incremental build number in the marketing version number as well.
The following is an example that takes a marketing version number in the x.y.z format and increments the last part of it.

	config.info_plist do |info|
  	  info.version = info.version.to_i + 1
  	  marketing_version = Versionomy.parse(info.marketing_version)
  	  info.marketing_version = marketing_version.bump(:tiny).to_s
  	  info.save
	end

You can read more about Versionomy at their [site](https://github.com/dazuma/versionomy)


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

	# installs profile into ~/Library
	Xcode::ProvisioningProfile.new("Myprofile.mobileprovision").install

Or enumerate installed profiles:

	Xcode::ProvisioningProfile.installed_profiles.each do |p|
		p.uninstall		# Removes the profile from ~/Library/
	end

### Deployment

#### [Testflight](http://testflightapp.com)

The common output of this build/package process is to upload to Testflight.  This is pretty simple with Xcoder:

	# Optionally do this, saves doing it again and again
	Xcode::Deploy::Testflight.defaults :api_token => 'some api token', :team_token => 'team token'

	builder.deploy :testflight,
		:api_token 	=> API_TOKEN,
		:team_token => TEAM_TOKEN,
		:notes 		=> "some release notes",
 	  	:notify 	=> true,		# Whether to send a notification to users, default is true
      	:lists 		=> ["AList"]  	# The lists to distribute the build to

You can also optionally set the HTTP_PROXY environment variable.

#### Deploying to Amazon S3

You can upload the output ipa to an arbitrary buckey on S3

	builder.deploy :s3,
		:bucket => "mybucket",
		:access_key_id => "access id",
		:secret_access_key => "access key",
		:dir => "options/path/within/bucket"

#### Deploying to a web server (SSH)

The output of the build/package process can be deployed to a remote web server.
You can use SSH with the following syntax:

	builder.deploy :ssh,
		:host => "mywebserver.com",
		:username => "myusername",
		:password => "mypassword",
		:dir => "/var/www/mywebserverpath",
		:base_url => "http://mywebserver.com/"

#### Deploying to a web server (FTP)

The output of the build/package process can be deployed to a remote web server.
You can upload the files through FTP with the following syntax:

	builder.deploy :ftp,
		:host => "ftp.mywebserver.com",
		:username => "myusername",
		:password => "mypassword",
		:dir => "/mywebserverpath",
		:base_url => "http://mywebserver.com/"


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

```ruby
# Copy the physical source files into the project path `Vendor/Reachability`
FileUtils.cp_r "examples/Reachability/Vendor", "spec/TestProject"

source_files = [ 'Vendor/Reachability/Reachability.m' , 'Vendor/Reachability/Reachability.h' ]

# Create and traverse to the group Reachability within the Vendor folder
project.group('Vendor/Reachability') do
 # Create files for each source file defined above
 source_files.each |source| create_file source }
end
```

Within the project file the groups in the path are created or found and then file references are added for the two specified source files. Xcoder only updates the logical project file, it does not copy physical files, that is done by the FileUtils.


### Adding source file to the sources build phase of a target

```ruby
source_file = project.file('Vendor/Reachability/Reachability.m')

project.target('TestProject').sources_build_phase do
  add_build_file source_file
end
```

Adding source files does not automatically include it in any of the built targets. That is done after you add the source file to the `sources_build_phase`. First we find the source file reference, select our target and then add it as a build file.

### Adding a System Framework to the project and built in a target

```ruby
cfnetwork_framework = project.frameworks_group.create_system_framework 'CFNetwork'

project.target('TestProject').framework_build_phase do
  add_build_file cfnetwork_framework
end
```

The **CFNetwork.framework** is added to the `Frameworks` group of the project and then added to the frameworks build phase.

### Add additional build phases to a target

```ruby
target.create_build_phases :copy_headers, :run_script
```

### Configure the Release build settings of a target

```ruby
release_config = target.config 'Release'
release_config.set 'ALWAYS_SEARCH_USER_PATHS', false

target.config 'Release' do |config|
  config.always_search_user_paths = false
  config.architectures = [ "$(ARCHS_STANDARD_32_BIT)", 'armv6' ]
  config.copy_phase_strip = true
  config.dead_code_stripping = false
  config.debug_information_format = "dwarf-with-dsym"
  config.c_language_standard = 'gnu99'
end
```

Configuration settings can be accessed through `get`, `set`, and `append` with their [Xcode Build Names](https://developer.apple.com/library/mac/#documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html#//apple_ref/doc/uid/TP40003931-CH3-SW110) or through convenience methods generated for most of the build settings (`property_name`, `property_name=`, `append_to_property_name`). The entire list of property names can be found in the [configuration](https://github.com/rayh/xcoder/blob/master/lib/xcode/configuration.rb#L158).


### Saving your changes!

```ruby
project.save!
```

The saved file output is slightly different than what you normally see when you view a Xcode project file. Luckily, Xcode will fix the format of the file if you make any small changes to the project that requires it to save.

### More Examples

Within the `specs/integration` folder there are more examples.

## Tests

There are some basic RSpec tests in the project which I suspect /wont/ work on machines without my identity installed.

Currently these tests only assert the basic project file parsing and build code and do not perform file modification tests (e.g. for info plists) or provisioning profile/keychain importing

## Automation and CI (BETA)

NOTE: This is only available in HEAD, you will need to install this gem from source to get this Buildspec support and the xcoder tool

This stuff is a work-in-progress and is subject to change.

Xcoder provides a simple mechanism to help with automating builds and CI.  First, define a Buildspec file in the root of your project with contents like this:

	# Assumes identity is first in keychain
	group :adhoc do

	  # Which project/target/config, or workspace/scheme to use
	  use :MyProject, :target => :MyTarget, :config => :Release

	  # The mobile provision that should be used
	  profile 'Provisioning/MyProject_AdHoc.mobileprovision'

	  # Keychain is option, allows isolation of identities per-project without
	  # polluting global keychain
	  keychain 'Provisioning/build.keychain', 'build'

	  deploy :testflight,
	    :api_token => 'api token',
	    :team_token => 'team token',
	    :notify => true,
	    :lists => ['Internal'],
	    :notes => `git log -n 1`
	end

You can then invoke the project using the xcoder command line:

	# Invoke the default task (deploy)
	xcoder -r

	# Invoke a specific task
	xcoder -r adhoc:package

	# Get a list of tasks
	xcoder -T

This is a bit of a work-in-progress and an attempt to allow projects to provide a minimal declaration of how their artifacts should be built and where they should go.  Integration with CI (Jenkins, for example) or just running locally from the command line should be simple.

## Feedback

Please raise issues if you find defects or have a feature request.

## License

Xcoder is released under the MIT License.  http://www.opensource.org/licenses/mit-license
