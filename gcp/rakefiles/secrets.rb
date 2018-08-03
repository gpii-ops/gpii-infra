require "base64"
require "openssl"
require "securerandom"
require "json"
require "yaml"

class Secrets

  KMS_KEYRING = "keyring"

  SECRETS_DIR = "secrets"
  SECRETS_FILE = "secrets.yaml"

  GOOGLE_CLOUD_API = "https://www.googleapis.com"
  GOOGLE_KMS_API = "https://cloudkms.googleapis.com"

  # This method is looking for SECRETS_FILE files in module directories (modules/*), which should have the following structure:
  #
  # secrets:
  #  - secret_module_admin_password
  #  - secret_module_another_secret
  #  - secret_module_and_one_more_secret
  # encryption_key: default
  #
  # Attribute "encryption_key" is optional – if not present, module name will be used as Key name
  # After collecting, method returns the Hash with collected secrets, where the keys are KMS Encryption Keys and the values are
  # lists of individual credentials (e.g. couchdb_password) managed with that KMS Encryption Key
  #
  # In case duplicated secrets found, exception is raised
  # All secrets must start with special prefix, otherwise exception is raised
  #
  # For prefix "secret_" random hexadecimal string(16) will be generated if ENV value not set
  # For prefix "key_" new OpenSSL aes-256-cfb key will be generated and packed in Base64 if ENV value not set
  #
  # We also advice to add module name to each secret's name (e.g. "secret_couchdb_admin_password" instead of just "secret_admin_password")
  # to avoid naming collisions, since secrets scope is global
  def self.collect_secrets()
    ENV['TF_VAR_keyring_name'] = Secrets::KMS_KEYRING

    encryption_keys = []
    collected_secrets = {}
    secrets_to_modules = {}

    Dir["../../modules/**/#{Secrets::SECRETS_FILE}"].each do |module_secrets_file|
      module_name = File.basename(File.dirname(module_secrets_file))
      module_secrets = YAML.load(File.read(module_secrets_file))

      encryption_key = module_secrets['encryption_key'] ? module_secrets['encryption_key'] : module_name
      encryption_keys << %Q|"#{encryption_key}"|

      if collected_secrets[encryption_key]
        collected_secrets[encryption_key].concat(module_secrets['secrets'])
      else
        collected_secrets[encryption_key] = module_secrets['secrets']
      end
      module_secrets['secrets'].each do |secret_name|
        if !(secret_name.start_with?("secret_") || secret_name.start_with?("key_"))
          raise "ERROR: Can not use secret with name '#{secret_name}' for module '#{module_name}'!\n \
            Secret name must start with 'secret_' or 'key_'!"
        elsif secrets_to_modules.include? secret_name
          raise "ERROR: Can not use secret with name '#{secret_name}' for module '#{module_name}'!\n \
            Secret '#{secret_name}' is already in use by module '#{secrets_to_modules[secret_name]}'!"
        end
        ENV["TF_VAR_#{secret_name}"] = ""
        secrets_to_modules[secret_name] = module_name
      end
    end

    encryption_keys.uniq!
    ENV["TF_VAR_encryption_keys"] = %Q|[ #{encryption_keys.join(", ")} ]|

    return collected_secrets
  end


  # This method is setting secret ENV variables collected from modules
  #
  # When encrypted secret file for current env is not present it GS bucket,
  # for every secret it first looks for ENV[secret_name.upcase] and, if it is not set,
  # populates secret with random nonse, and then uploads to corresponding GS bucket.
  #
  # When encrypted secret file is present, it always uses its decrypted data as a source for secrets.
  # Use `rake destroy_secrets[KEY_NAME]` to forcefully repopulate secrets for target encryption key
  def self.set_secrets(collected_secrets, exekube_cmd)
    return if collected_secrets.empty?

    FileUtils.mkdir_p Secrets::SECRETS_DIR

    collected_secrets.each do |encryption_key, secrets|
      decrypted_secrets = fetch_secrets(encryption_key, exekube_cmd)

      if decrypted_secrets
        decrypted_secrets.each do |secret_name, secret_value|
          ENV["TF_VAR_#{secret_name}"] = secret_value
        end
      else
        populated_secrets = {}
        secrets.each do |secret_name|
          if ENV[secret_name.upcase].to_s.empty?
            if secret_name.start_with?("key_")
              key = OpenSSL::Cipher.new("aes-256-cfb").encrypt.random_key
              secret_value = Base64.encode64(key).chomp
            else
              secret_value = SecureRandom.hex
            end
          else
            secret_value = ENV[secret_name.upcase]
          end
          ENV["TF_VAR_#{secret_name}"] = secret_value
          populated_secrets[secret_name] = secret_value
        end

        push_secrets(populated_secrets, encryption_key, exekube_cmd)
      end
    end
  end

  def self.push_secrets(secrets, encryption_key, exekube_cmd)
    gs_bucket = "#{ENV['TF_VAR_project_id']}-#{encryption_key}-secrets"
    encoded_secrets = Base64.encode64(secrets.to_json).delete!("\n")

    puts "[secret-mgmt] Encrypting secrets for key '#{encryption_key}'..."
    encrypted_secrets = %x{
      #{exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X POST \"#{Secrets::GOOGLE_KMS_API}/v1/projects/#{ENV['TF_VAR_project_id']}/locations/global/keyRings/#{Secrets::KMS_KEYRING}/cryptoKeys/#{encryption_key}:encrypt\" \
      -d \"{\\\"plaintext\\\":\\\"#{encoded_secrets}\\\"}\"'
    }

    begin
      responce_check = JSON.parse(encrypted_secrets)
    rescue
      puts "ERROR: Unable to parse encrypted secrets data for key '#{encryption_key}', terminating!"
      raise
    end

    puts "[secret-mgmt] Uploading encrypted secrets for key '#{encryption_key}' into GS bucket..."
    encrypted_secrets = Base64.encode64(encrypted_secrets).delete!("\n")
    api_call_data = %x{
      #{exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X POST \"#{Secrets::GOOGLE_CLOUD_API}/upload/storage/v1/b/#{gs_bucket}/o?uploadType=media&name=#{Secrets::SECRETS_FILE}\" \
      -d \"#{encrypted_secrets}\"'
    }

    begin
      responce_check = JSON.parse(api_call_data)
    rescue
      puts "ERROR: Unable to upload encrypted secrets for key '#{encryption_key}' into GS bucket, terminating!"
      raise
    end
  end

  def self.fetch_secrets(encryption_key, exekube_cmd)
    gs_bucket = "#{ENV['TF_VAR_project_id']}-#{encryption_key}-secrets"
    gs_secrets_file = "#{gs_bucket}/o/#{Secrets::SECRETS_FILE}"

    puts "[secret-mgmt] Checking if secrets file for key '#{encryption_key}' is present in GS bucket..."
    api_call_data = %x{
      #{exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X GET \"#{Secrets::GOOGLE_CLOUD_API}/storage/v1/b/#{gs_secrets_file}\"'
    }

    begin
      gs_secrets = JSON.parse(api_call_data)
    rescue
      puts "ERROR: Unable to parse GS secrets file data for key '#{encryption_key}', terminating!"
      raise
    end

    if gs_secrets['error'] && gs_secrets['error']['code'] == 404
      puts "[secret-mgmt] Encrypted secrets for key '#{encryption_key}' is missing in GS bucket..."
      return
    end

    puts "[secret-mgmt] Retrieving encrypted secrets for key '#{encryption_key}' from GS bucket..."
    api_call_data = %x{
      #{exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X GET \"#{Secrets::GOOGLE_CLOUD_API}/storage/v1/b/#{gs_secrets_file}?alt=media\"'
    }

    gs_secrets = JSON.parse(Base64.decode64(api_call_data))
    if !gs_secrets['ciphertext']
      puts "ERROR: Unable to extract ciphertext from YAML data for key '#{encryption_key}', terminating!"
      raise
    end

    puts "[secret-mgmt] Decrypting secrets for key '#{encryption_key}' with KMS cert..."
    decrypted_secrets = %x{
      #{exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X POST \"#{Secrets::GOOGLE_KMS_API}/v1/projects/#{ENV['TF_VAR_project_id']}/locations/global/keyRings/#{Secrets::KMS_KEYRING}/cryptoKeys/#{encryption_key}:decrypt\" \
      -d \"{\\\"ciphertext\\\":\\\"#{gs_secrets['ciphertext']}\\\"}\"'
    }

    begin
      decrypted_secrets = JSON.parse(decrypted_secrets)
      decrypted_secrets = JSON.parse(Base64.decode64(decrypted_secrets['plaintext']))
    rescue
      puts "ERROR: Unable to parse secrets data for key '#{encryption_key}', terminating!"
      raise
    end

    return decrypted_secrets
  end
end

# vim: et ts=2 sw=2:
