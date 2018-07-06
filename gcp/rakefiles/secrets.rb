require "securerandom"
require "yaml"

class Secrets

  KMS_KEYRING = "keyring"
  KMS_DEFAULT_KEY = "default"

  SECRETS_FILE = "secrets.yaml"

  def self.collect_secrets()
    ENV['TF_VAR_keyring_name'] = Secrets::KMS_KEYRING
    $compose_env << "TF_VAR_keyring_name"

    encryption_keys = []
    secrets = {}
    %x{find ../../modules -maxdepth 2 | grep #{Secrets::SECRETS_FILE}}.split.each do |mod|
      mod_default_key = File.dirname(mod).split('/').last
      mod_secrets_cfg = YAML.load(File.read(mod))

      kms_key = mod_secrets_cfg['kms_key'] ? mod_secrets_cfg['kms_key'] : mod_default_key
      encryption_keys << "\"#{kms_key}\"" unless encryption_keys.include? kms_key

      if secrets[kms_key]
        secrets[kms_key].concat(mod_secrets_cfg['secrets'])
      else
        secrets[kms_key] = mod_secrets_cfg['secrets']
      end
      mod_secrets_cfg['secrets'].each do |secret|
        $compose_env << "TF_VAR_#{secret}"
      end
    end

    ENV["TF_VAR_encryption_keys"] = %Q|[ #{encryption_keys.join(", ")} ]|
    $compose_env << "TF_VAR_encryption_keys"

    return secrets
  end

  def self.set_secrets(secrets)
    if secrets
      secrets.each do |key, secrets|
        sh_filter "#{$exekube_cmd} secrets-fetch #{key}"

        secrets_file = "./secrets/#{key}/#{Secrets::SECRETS_FILE}"
        if File.file?(secrets_file)
          secrets = YAML.load(File.read(secrets_file))
          secrets.each do |key, val|
            ENV["TF_VAR_#{key}"] = val
          end
          File.delete(secrets_file)
        else
          populated_secrets = {}
          secrets.each do |secret|
            ENV["TF_VAR_#{secret}"] = populated_secrets[secret] = SecureRandom.hex
          end
          puts "Secret file '#{secrets_file}' not found. I will create one."
          File.open(secrets_file, 'w+') do |file|
            file.write(populated_secrets.to_yaml)
          end

          sh_filter "#{$exekube_cmd} secrets-push #{key}"
          File.delete(secrets_file)
        end
      end
    end
  end
end

# vim: et ts=2 sw=2:
