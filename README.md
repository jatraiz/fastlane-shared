# fastlane-shared

Repository for fastlane files and utilities common to Raizlabs projects.

## Shared Fastfile

The SharedFastfile.rb provides functionality that should be common to all RZ iOS project builds:

- Shorthand for common actions such as build and test with sensible defaults
- Default behavior for unlocking keychains
- All output redirected to a common build location within the project structure

You can import the `SharedFastfile.rb` in your own `Fastfile` like this:

```
import_from_git(url:"git@github.com:Raizlabs/fastlane-shared.git", path:"SharedFastfile.rb")
```
See `ExampleFastfile` for an example of what your Fastfile might look like. Note that the `SharedFastfile.rb` does not prescribe lanes, bbut rather, provides helper functionality to aid you in creating your own lanes. 

Every action helper is keyed off a common "app name" which is provided via the `RZ_APP_NAME` environment variable. Other actions require various environment variables be present, see the header doc in the `SharedFastfile.rb` for more info. In addition to specifying these variables, your directory structure should look like this:

- {root dir}
	- app
		- {app name}
		- {app name}.xcodeproj
		- {app name}.xcworkspace
		- Podfile
		- Signing
			- {app name}.keychain (should contain app-sepcific signing certs)
			- Raizlabs.keychain (should contain Raizlabs signing certs)
			- {app name}.mobileprovision (and any other provisioning profiles)
		- fastlane (all fastlane files)
	- Gemfile
	- Gemfile.lock
	- README.md

