def setup_vars(env_short)
  shared_envs = ["stg", "prd"]
  if ENV["TF_VAR_environment"].nil?
    if shared_envs.include?(env_short)
      ENV["TF_VAR_environment"] = env_short
    else
      if ENV["USER"].nil? || ENV["USER"].empty?
        raise "ERROR: Please set $USER (or $TF_VAR_environment directly, if you're sure you know what you're doing)."
      end
      ENV["TF_VAR_environment"] = "#{env_short}-#{ENV["USER"]}"
    end
  end
  ENV["TF_VAR_cluster_name"] = "#{ENV["TF_VAR_environment"]}.gpii.net"

  # If rake has already set up TMPDIR, don't set it again. Otherwise, we end up
  # with a second 'rake-tmp/environment' in the path.
  if ENV["RAKE_TMPDIR_ALREADY_SET"]
    tmpdir_base = ENV["TMPDIR"]
    @tmpdir = tmpdir_base
  else
    tmpdir_base = ENV["TMPDIR"] || "/tmp"
    @tmpdir = File.absolute_path("#{tmpdir_base}/rake-tmp/#{ENV["TF_VAR_environment"]}")
  end
  @tmpdir_prereqs = "#{@tmpdir}-prereqs"
  ENV["TMPDIR"] = @tmpdir

  directory @tmpdir
  CLOBBER << @tmpdir

  # We use a separate tmpdir so we don't mix up the prereq terraform run's
  # downloaded modules with the main terraform run's downloaded modules.
  directory @tmpdir_prereqs
  CLOBBER << @tmpdir_prereqs

  ENV["RAKE_TMPDIR_ALREADY_SET"] = "true"
end
