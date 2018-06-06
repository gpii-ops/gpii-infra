require "securerandom"
require "yaml"

class Vars
  def self.set_vars(env)
    if ENV["TF_VAR_project_id"].nil?
      puts "  ERROR: TF_VAR_project_id must be set!"
      puts "  Do this: export TF_VAR_project_id=<your name>-<env>"
      puts "  and try again."
      raise ArgumentError, "TF_VAR_project_id must be set"
    end
    ENV["ENV"] = env
    if ENV["ORGANIZATION_ID"].nil?
      ENV["ORGANIZATION_ID"] = "247149361674"  # RtF Organization
    end
    if ENV["BILLING_ID"].nil?
      ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F"  # RtF Billing Account
    end

    # Hack to avoid changes in gpii-version-updater
    version_file = '../aws/modules/deploy/version.yml'
    versions = YAML.load(File.read(version_file))
    if versions['flowmanager']
      ENV['TF_VAR_flowmanager_repository'] = versions['flowmanager'].split('@')[0]
      ENV['TF_VAR_flowmanager_checksum'] = versions['flowmanager'].split('@')[1]
    end
    if versions['preferences']
      ENV['TF_VAR_preferences_repository'] = versions['preferences'].split('@')[0]
      ENV['TF_VAR_preferences_checksum'] = versions['preferences'].split('@')[1]
    end
    if versions['gpii-dataloader']
      ENV['TF_VAR_dataloader_repository'] = versions['gpii-dataloader'].split('@')[0]
      ENV['TF_VAR_dataloader_checksum'] = versions['gpii-dataloader'].split('@')[1]
    end
  end

  def self.set_secrets()
    saved_secrets_file_path = "live/#{ENV['ENV']}/secrets/#{ENV["TF_VAR_project_id"]}-secrets.yml"

    begin
      @secrets = YAML.load(File.read(saved_secrets_file_path))
    rescue Errno::ENOENT
      generate_file = true
      @secrets = Hash.new
    end

    [ \
      'couchdb_admin_username', \
      'couchdb_admin_password', \
      'couchdb_secret', \
    ].each do |secret|
      unless ENV[secret.upcase].to_s.empty?
        @secrets[secret] = ENV[secret.upcase]
        # we don't want to store Environment variables
        generate_file = false
      end
      @secrets[secret] = SecureRandom.hex if @secrets[secret].to_s.empty?
      ENV["TF_VAR_#{secret}"] = @secrets[secret]
    end

    if generate_file
      puts "Secret file #{saved_secrets_file_path} for this deployment not found. I will create one."
      File.open(saved_secrets_file_path, 'w+') do |file|
        file.write(@secrets.to_yaml)
      end
    end
  end
end

# vim: et ts=2 sw=2:
