# SharedFastfile.rb
#
# A shared Fastfile with standard lanes and helpers.
#
# This Fastfile assumes a number of enviornment variables. Set them in your build system
# or provide them locally in fastlane/.env.default file.
#
# $RZ_APP_NAME - The name of the app. Should match the name of the Xcode project.
# $RZ_BUILD_DIR - The location for all build artifacts, logs, and temp files. Defaults to ./build if not set.
# $RZ_APP_KEYCHAIN_PASSWORD - The password for a keychain containing app certs.
#                             It is assumed that this keychain is at ./Signing/$RZ_APP_NAME.keychain
# $RZ_KEYCHAIN_PASSWORD - The password for a keychain containing the Raizlabs certs.
#                             It is assumed that this keychain is at ./Signing/Raizlabs.keychain
# $RZ_BUILD_NUMBER - The build number to be used when incrementing the Xcode build number.
#
# Hockey Upload - You ust set $FL_HOCKEY_PUBLIC_IDENTIFIER and $FL_HOCKEY_API_TOKEN in order for the
# hockey fastlane action to function.

platform :ios do

  # Environment
  def app_name() "#{ENV['RZ_APP_NAME']}" end
  def product_name() "#{ENV['RZ_PRODUCT_NAME']}" end
  def clientKeychain_name() "#{ENV['CLIENT_KEYCHAIN_NAME']} end
  def xcodeproj_name() "#{ENV['RZ_APP_PROJECT_NAME']}.xcodeproj" end
  def workspace_name() "#{ENV['RZ_APP_PROJECT_NAME']}.xcworkspace"  end

  def build_dir()
    dir = "#{ENV['RZ_BUILD_DIR']}"
    if dir.length == 0
      dir = './build'
    end

    return dir
   end

  # Lanes

  def super_before()
    if app_name.length > 0
      puts "Proceeding with app_name: #{app_name}"
    else
      raise "$RZ_APP_NAME environment variable must be set".red
    end

    clean_build_dir
    keychain("./Signing/" + clientKeychain_name +"".keychain", "#{ENV['RZ_APP_KEYCHAIN_PASSWORD']}")
    keychain("./Signing/Raizlabs.keychain", "#{ENV['RZ_KEYCHAIN_PASSWORD']}")
  end

  desc "Run the unit tests"
  lane :test do
    run_tests(false)
  end

  # Helpers

  def build(scheme, export_method, use_legacy_build = true)
    puts "Building scheme #{scheme} legacy: #{use_legacy_build} export: #{export_method}"

    set_build_number
    gym(
      clean: true,
      output_directory: build_dir,
      archive_path: build_dir + "/" + app_name,
      buildlog_path: build_dir + "/logs",
      scheme: scheme,
      workspace: workspace_name,
      xcargs: "BUILD_NUMBER=#{build_number}",
      use_legacy_build_api: use_legacy_build,
      export_method: export_method
    )
  end

  def clean_build_dir()
    puts "Cleaning build directory: #{build_dir}"
    sh "rm -rf ../#{build_dir}"
    sh "mkdir ../#{build_dir}"
  end

  def run_tests(skip_build=true)
    scan(
      output_types: 'junit',
      scheme: app_name,
      workspace: workspace_name,
      output_directory: build_dir + "/test",
      buildlog_path: build_dir + "/test/logs",
      derived_data_path: build_dir + "/test/deriveddata",
      skip_slack: true,
      skip_build: skip_build
  )
  end

  def upload_to_hockey()
    hockey_app_id = "#{ENV['FL_HOCKEY_PUBLIC_IDENTIFIER']}"
    if hockey_app_id.length > 0
      puts "Uploading to Hockey..."
      hockey(ipa: "#{build_dir}/#{product_name}.ipa")
    else
      puts "Missing hockey env. variables, specify the fastlane 'FL_' variables and try again"
    end
  end

  def set_build_number()
    increment_build_number(build_number: build_number, xcodeproj: xcodeproj_name )
  end

  def build_number()
    build_number = "#{ENV['RZ_BUILD_NUMBER']}"
    if build_number.length > 0
      return build_number
    else
      return 1
    end

  end

  def keychain(path, password)
    if password.length > 0
      unlock_keychain(path: path, password: password)
    else
      puts "Password not provided for keychain at #{path}, not unlocking."
    end
  end

end

# Utility

def build_number_commit_count()
  `git rev-list HEAD --count`.chomp()
end
