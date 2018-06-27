require "securerandom"
require "yaml"

class Secrets

  def self.set_secrets()
    saved_secrets_file_path = "../#{ENV['ENV']}/secrets/#{ENV["TF_VAR_project_id"]}-secrets.yml"

    begin
      secrets = YAML.load(File.read(saved_secrets_file_path))
    rescue Errno::ENOENT
      generate_file = true
      secrets = Hash.new
    end

    [ \
      'couchdb_admin_username', \
      'couchdb_admin_password', \
      'couchdb_secret', \
    ].each do |secret|
      unless ENV[secret.upcase].to_s.empty?
        secrets[secret] = ENV[secret.upcase]
        # we don't want to store Environment variables
        generate_file = false
      end
      secrets[secret] = SecureRandom.hex if secrets[secret].to_s.empty?
      ENV["TF_VAR_#{secret}"] = secrets[secret]
    end

    if generate_file
      puts "Secret file #{saved_secrets_file_path} for this deployment not found. I will create one."
      File.open(saved_secrets_file_path, 'w+') do |file|
        file.write(secrets.to_yaml)
      end
    end

    return secrets
  end
end
