platform :ios do

  # Environment

  def app_name() "#{ENV['RZ_APP_NAME']}" end
  def xcodeproj_name() "#{app_name}.xcodeproj" end
  def workspace_name() "#{app_name}.xcworkspace" end
  def ipa_output_dir() "#{ENV['IPA_OUTPUT_DIR']}" end

  # Lanes

  before_all do

    puts "##teamcity[buildNumber '#{build_number}.{build.number}']"

    if app_name.length > 0
      puts "Proceeding with app_name: #{app_name}"
    else
      raise "app_name environment variable must be set".red
    end

    clean_build_dir
    unlock_keychain(path: "./Signing/#{app_name}.keychain")
  end

  # TODO: figure out why this doesn't work
  # after_all do
  #   report_path = "#{ipa_output_dir}/report.junit"
  #   puts "##teamcity[importData type='junit' path='#{report_path}']"
  # end

  desc "Develop"
  lane :develop do
    build("#{app_name}", 'enterprise')
    run_tests
    upload_to_hockey
  end

  desc "Ad Hoc"
  lane :adhoc do
    build("#{app_name}-AdHoc", 'ad-hoc')
    run_tests
    upload_to_hockey
  end

  desc "App Store"
  lane :appstore do
    build("#{app_name}-AppStore")
    run_tests
  end

  desc "Run the unit tests"
  lane :test do
    run_tests
  end

  # Helpers

  def build(scheme, export_method = '')
    set_build_number_commit_count
    gym(
      clean: true,
      output_directory: ipa_output_dir,
      scheme: scheme,
      workspace: workspace_name,
      xcargs: "BUILD_NUMBER=#{build_number}",
      use_legacy_build_api: true,
      export_method: export_method
    )
  end

  def clean_build_dir()
    sh "rm -rf ../$IPA_OUTPUT_DIR"
    sh "mkdir ../$IPA_OUTPUT_DIR"
  end

  def run_tests()
    scan(
      output_types: 'junit',
      scheme: app_name,
      workspace: workspace_name,
      output_directory: ipa_output_dir
  )
  end

  def upload_to_hockey()
    hockey_app_id = "#{ENV['FL_HOCKEY_PUBLIC_IDENTIFIER']}"
    if hockey_app_id.length > 0
      puts "Uploading to Hockey..."
      hockey(ipa: "#{ipa_output_dir}/#{app_name}.ipa")
    else
      puts "Missing hockey env. variables, specify the fastlane 'FL_' variables and try again"
    end
  end

  def set_build_number_commit_count()
    commit_count = `git rev-list HEAD --count`
    increment_build_number(build_number: commit_count, xcodeproj: xcodeproj_name )
  end

end

# Global Utils

def build_number
  `git rev-list HEAD --count`.chomp()
end
