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
  ENV["TF_VAR_cluster_name"] = "k8s-#{ENV["TF_VAR_environment"]}.gpii.net"

  tmpdir_base = ENV["TMPDIR"] || "/tmp"
  @tmpdir = File.absolute_path("#{tmpdir_base}/rake-tmp/#{ENV["TF_VAR_environment"]}")
  @tmpdir_prereqs = "#{@tmpdir}-prereqs"
  ENV["TMPDIR"] = @tmpdir

  directory @tmpdir
  CLOBBER << @tmpdir
end
