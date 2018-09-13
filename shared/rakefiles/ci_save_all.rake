# This lives in its own file because we need a clean
# environment, not pre-populated with configuration like
# TF_VAR_project_id which will be different for different
# environments.
desc "[CI ONLY] Fetch and save GCP credentials for all environments in live/"
task :default do
  ENV["USER"] = "gitlab-runner"  # User that runs CI
  ["common", "gcp"].each do |project_type|
    environments_dir = File.expand_path("../../../shared/#{project_type}/live", __FILE__)
    environments = Dir.glob(environments_dir + "/*").select { |f| File.directory? f }
    puts "WARNING! This script will delete ALL secrets-backups volumes and replace them"
    puts "WARNING! with new backups! It will run 'rake clobber' at the end, clearing state"
    puts "WARNING! for any ongoing runs!"
    puts "WARNING!"
    puts "WARNING!  The following environments will be affected:"
    puts "           #{environments}"
    puts "WARNING!"
    puts "WARNING! Hit Ctrl-C now if this is not what you want!"
    puts "WARNING! Otherwise, press enter."
    STDIN.gets
    environments.each do |env|
      sh "cd #{env} && \
        rake configure_serviceaccount_ci_clobber && \
        rake configure_serviceaccount && \
        rake configure_serviceaccount_ci_save && \
        rake clobber \
      "
    end
  end
end

# vim: et ts=2 sw=2:

