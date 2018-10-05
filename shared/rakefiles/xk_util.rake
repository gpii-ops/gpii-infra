# This task rotates :secret for target :encryption_key.
# New value for the secret can be set via env var TF_VAR_secret_name,
# otherwise new value will be generated automatically.
# Old secret value will be set to TF_VAR_secret_name_rotated until rotation is finished.
# Arbitrary command to execute after rotation can be set with :cmd argument
task :rotate_secret, [:secret, :encryption_key, :cmd] => [:configure_serviceaccount] do |taskname, args|
  if args[:secret].nil? || args[:secret].size == 0
    puts "  ERROR: Argument :secret not present!"
    raise
  elsif args[:encryption_key].nil? || args[:encryption_key].size == 0
    puts "  ERROR: Argument :encryption_key not present!"
    raise
  end

  @secrets = Secrets.collect_secrets()

  if ENV["TF_VAR_#{args[:secret]}"].nil?
    puts "  ERROR: Secret '#{args[:secret]}' does not exist!"
    raise
  elsif @secrets[args[:encryption_key]].nil?
    puts "  ERROR: Encryption key '#{args[:encryption_key]}' does not exist!"
    raise
  end

  Secrets.set_secrets(@secrets)
  ENV["TF_VAR_#{args[:secret]}_rotated"] = ENV["TF_VAR_#{args[:secret]}"]
  ENV["TF_VAR_#{args[:secret]}"] = ""

  Secrets.set_secrets(@secrets, true)

  sh_filter "#{@exekube_cmd} #{args[:cmd]}" if args[:cmd]
end
