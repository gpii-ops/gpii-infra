require "base64"
require "json"
require "openssl"
require "securerandom"
require "yaml"

class Secrets

  KMS_KEYRING_NAME = "keyring"

  SECRETS_DIR    = "secrets"
  SECRETS_FILE   = "secrets.yaml"
  SECRETS_CONFIG = "/project/modules/gcp-secret-mgmt/config.yaml"

  GOOGLE_CLOUD_API = "https://www.googleapis.com"
  GOOGLE_KMS_API   = "https://cloudkms.googleapis.com"

  attr_reader :collected_secrets
  attr_reader :infra_region
  attr_reader :project_id

  def initialize(project_id, infra_region, decrypt_with_key_from_region=false)
    @project_id = project_id
    @infra_region = infra_region
    @decrypt_with_key_from_region = decrypt_with_key_from_region
  end

  def load_secrets_config
    return YAML.load(File.read(Secrets::SECRETS_CONFIG))
  end

  # This method is looking for SECRETS_FILE files in module directories (modules/*), which should have the following structure:
  #
  # secrets:
  #  - secret_module_admin_password
  #  - secret_module_another_secret
  #  - secret_module_and_one_more_secret
  # encryption_key: default
  #
  # Config file gcp/modules/gcp-secret-mgmt/config.yaml
  # is needed to preserve the order of encryption keys.
  # All used encryption keys must be present in that config, otherwise exception is raised
  # More info: https://issues.gpii.net/browse/GPII-3456
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
  def collect_secrets()
    unless File.file?(Secrets::SECRETS_CONFIG)
      puts "[secret-mgmt] Secrets config not present, skipping..."
      @collected_secrets = {}
      return
    end

    ENV['TF_VAR_keyring_name'] = Secrets::KMS_KEYRING_NAME

    collected_secrets = {}
    secrets_to_modules = {}

    Dir["./modules/**/#{Secrets::SECRETS_FILE}"].each do |module_secrets_file|
      module_name = File.basename(File.dirname(module_secrets_file))
      module_secrets = YAML.load(File.read(module_secrets_file))

      encryption_key = module_secrets['encryption_key'] ? module_secrets['encryption_key'] : module_name

      if collected_secrets[encryption_key]
        collected_secrets[encryption_key].concat(module_secrets['secrets'])
      else
        collected_secrets[encryption_key] = module_secrets['secrets']
      end
      module_secrets['secrets'].each do |secret_name|
        if !(secret_name.start_with?("secret_") || secret_name.start_with?("key_") || secret_name.start_with?("uuid_"))
          raise "ERROR: Can not use secret with name '#{secret_name}' for module '#{module_name}'!\n \
            Secret name must start with 'secret_', 'key_' or 'uuid_'!"
        elsif secrets_to_modules.include? secret_name
          raise "ERROR: Can not use secret with name '#{secret_name}' for module '#{module_name}'!\n \
            Secret '#{secret_name}' is already in use by module '#{secrets_to_modules[secret_name]}'!"
        end
        ENV["TF_VAR_#{secret_name}"] = "" unless ENV["TF_VAR_#{secret_name}"]
        secrets_to_modules[secret_name] = module_name
      end
    end

    encryption_keys = {}
    secrets_config = load_secrets_config()
    secrets_config["encryption_keys"].each do |encryption_key|
      encryption_keys[encryption_key] = %Q|"#{encryption_key}"|
    end

    leftover_keys = collected_secrets.keys - encryption_keys.keys
    unless leftover_keys.empty?
      puts "ERROR: Secret keys: \"#{leftover_keys.join(", ")}\" not present in"
      puts "ERROR: gcp/modules/gcp-secret-mgmt/config.yaml"
      raise
    end

    ENV["TF_VAR_encryption_keys"] = %Q|[ #{encryption_keys.values.join(", ")} ]|

    @collected_secrets = collected_secrets
  end

  # This method is setting secret ENV variables collected from modules
  #
  # When encrypted secret file for current env is not present it GS bucket,
  # for every secret it first looks for ENV["TF_VAR_#{secret_name}"] and, if it is not set,
  # populates secret with random nonse, and then uploads to corresponding GS bucket.
  #
  # When encrypted secret file is present, it always uses its decrypted data as a source for secrets.
  # When `rotate_secrets` is set to true, secrets will be set from env vars, encrypted secret file will be
  # re-generated and re-uploaded into GS bucket.
  # Use `rake destroy_secrets[KEY_NAME]` to forcefully repopulate secrets for target encryption key.
  def set_secrets(rotate_secrets = false)
    if @collected_secrets.nil?
      raise "Called set_secrets() without first calling collect_secrets()"
    end
    @collected_secrets.each do |encryption_key, secrets|
      decrypted_secrets = fetch_secrets(encryption_key) unless secrets.empty? or rotate_secrets

      if decrypted_secrets
        decrypted_secrets.each do |secret_name, secret_value|
          ENV["TF_VAR_#{secret_name}"] = secret_value
        end

        push_secrets = false
        # If new secrets added into configuration, but encrypted secrets are already present
        new_secrets = secrets - decrypted_secrets.keys
        unless new_secrets.empty?
          puts "[secret-mgmt] Populating new secrets for key '#{encryption_key}': #{new_secrets.join(", ")}..."
          populated_secrets = populate_secrets(new_secrets)
          decrypted_secrets = populated_secrets.merge(decrypted_secrets)
          push_secrets = true
        end

        # If some secrets been removed from configuration, but still exist as encrypted secrets
        removed_secrets = decrypted_secrets.keys - secrets
        unless removed_secrets.empty?
          puts "[secret-mgmt] Found removed secrets for key '#{encryption_key}': #{removed_secrets.join(", ")}..."
          removed_secrets.each do |removed_secret|
            decrypted_secrets.delete(removed_secret)
          end
          push_secrets = true
        end

        push_secrets(decrypted_secrets, encryption_key) if push_secrets
      else
        next if secrets.empty?
        puts "[secret-mgmt] Populating secrets for key '#{encryption_key}'..."
        populated_secrets = populate_secrets(secrets)
        push_secrets(populated_secrets, encryption_key)
      end
    end

    # TODO: Next line should be removed once Terraform issue with GCS backend encryption is fixed
    # https://issues.gpii.net/browse/GPII-3329
    ENV['GOOGLE_ENCRYPTION_KEY'] = ENV['TF_VAR_key_tfstate_encryption_key']
  end

  def populate_secrets(secrets)
    populated_secrets = {}

    secrets.each do |secret_name|
      if ENV["TF_VAR_#{secret_name}"].to_s.empty?
        if secret_name.start_with?("key_")
          key = OpenSSL::Cipher::AES256.new.encrypt.random_key
          secret_value = Base64.strict_encode64(key)
        elsif secret_name.start_with?("uuid_")
          secret_value = SecureRandom.uuid
        else
          secret_value = SecureRandom.hex
        end
        ENV["TF_VAR_#{secret_name}"] = secret_value
      else
        secret_value = ENV["TF_VAR_#{secret_name}"]
      end
      populated_secrets[secret_name] = secret_value
    end

    return populated_secrets
  end

  def push_secrets(secrets, encryption_key)
    gs_bucket = "#{@project_id}-#{encryption_key}-secrets"
    encoded_secrets = Base64.encode64(secrets.to_json).delete!("\n")

    puts "[secret-mgmt] Retrieving primary key version for key '#{encryption_key}'..."
    encryption_key_version = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X GET \"#{Secrets::GOOGLE_KMS_API}/v1/projects/#{@project_id}/locations/#{@infra_region}/keyRings/#{Secrets::KMS_KEYRING_NAME}/cryptoKeys/#{encryption_key}\"
    }

    begin
      encryption_key_version = JSON.parse(encryption_key_version)
      encryption_key_version = get_crypto_key_version(encryption_key_version['primary']['name'])
    rescue
      debug_output "ERROR: Unable to get primary encryption key version for key '#{encryption_key}', terminating!", encryption_key_version
      raise
    end

    puts "[secret-mgmt] Encrypting secrets with key '#{encryption_key}' version #{encryption_key_version}..."
    encrypted_secrets = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X POST \"#{Secrets::GOOGLE_KMS_API}/v1/projects/#{@project_id}/locations/#{@infra_region}/keyRings/#{Secrets::KMS_KEYRING_NAME}/cryptoKeys/#{encryption_key}/cryptoKeyVersions/#{encryption_key_version}:encrypt\" \
      -d \"{\\\"plaintext\\\":\\\"#{encoded_secrets}\\\"}\"
    }

    begin
      response_check = JSON.parse(encrypted_secrets)
    rescue
      debug_output "ERROR: Unable to parse encrypted secrets data for key '#{encryption_key}', terminating!"
      raise
    end

    puts "[secret-mgmt] Uploading encrypted secrets for key '#{encryption_key}' into GS bucket..."
    encrypted_secrets = Base64.encode64(encrypted_secrets).delete!("\n")
    api_call_data = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X POST \"#{Secrets::GOOGLE_CLOUD_API}/upload/storage/v1/b/#{gs_bucket}/o?uploadType=media&name=#{Secrets::SECRETS_FILE}\" \
      -d \"#{encrypted_secrets}\"
    }

    begin
      response_check = JSON.parse(api_call_data)
    rescue
      debug_output "ERROR: Unable to upload encrypted secrets for key '#{encryption_key}' into GS bucket, terminating!"
      raise
    end
  end

  def get_decrypt_url(encryption_key)
    region = @infra_region
    # I'm adding this to assist with migration for GPII-3707. It can likely be
    # removed afterwards, as we no longer plan to use Keyrings in /global/.
    if @decrypt_with_key_from_region
      region = @decrypt_with_key_from_region
    end
    decrypt_url = "#{Secrets::GOOGLE_KMS_API}/v1/projects/#{@project_id}/locations/#{region}/keyRings/#{Secrets::KMS_KEYRING_NAME}/cryptoKeys/#{encryption_key}:decrypt"
    return decrypt_url
  end

  def fetch_secrets(encryption_key)
    gs_bucket = "#{@project_id}-#{encryption_key}-secrets"
    gs_secrets_file = "#{gs_bucket}/o/#{Secrets::SECRETS_FILE}"

    puts "[secret-mgmt] Checking if secrets file for key '#{encryption_key}' is present in GS bucket #{gs_bucket}..."
    api_call_data = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X GET \"#{Secrets::GOOGLE_CLOUD_API}/storage/v1/b/#{gs_secrets_file}\"
    }

    begin
      gs_secrets = JSON.parse(api_call_data)
    rescue
      debug_output "ERROR: Unable to parse GS secrets file data for key '#{encryption_key}', terminating!"
      raise
    end

    if gs_secrets['error'] && gs_secrets['error']['code'] == 404
      puts "[secret-mgmt] Encrypted secrets for key '#{encryption_key}' is missing in GS bucket..."
      return
    end

    puts "[secret-mgmt] Retrieving encrypted secrets for key '#{encryption_key}' from GS bucket..."
    api_call_data = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X GET \"#{Secrets::GOOGLE_CLOUD_API}/storage/v1/b/#{gs_secrets_file}?alt=media\"
    }

    gs_secrets = JSON.parse(Base64.decode64(api_call_data))
    unless gs_secrets['ciphertext']
      debug_output "ERROR: Unable to extract ciphertext from YAML data for key '#{encryption_key}', terminating!"
      if gs_secrets['error']
        puts gs_secrets['error']
      end
      raise
    end

    decrypt_url = get_decrypt_url(encryption_key)
    puts "[secret-mgmt] Decrypting secrets for key '#{encryption_key}' with KMS key #{decrypt_url}..."
    decrypted_secrets = %x{
      curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X POST \"#{decrypt_url}\" \
      -d \"{\\\"ciphertext\\\":\\\"#{gs_secrets['ciphertext']}\\\"}\"
    }

    begin
      decrypted_secrets = JSON.parse(decrypted_secrets)
      unless decrypted_secrets['plaintext']
        if decrypted_secrets['error']
          puts decrypted_secrets['error']
        end
        raise "Response from API is JSON but contains no key 'plaintext', so we can't parse it."
      end
      decrypted_secrets = JSON.parse(Base64.decode64(decrypted_secrets['plaintext']))
    rescue
      debug_output "ERROR: Unable to parse secrets data for key '#{encryption_key}', terminating!"
      raise
    end

    return decrypted_secrets
  end

  # This method creates new primary version for target encryption_key
  def create_key_version(encryption_key)
    puts "[secret-mgmt] Creating new primary version for key '#{encryption_key}'..."
    new_version = %x{
      gcloud kms keys versions create \
      --location #{@infra_region} \
      --keyring #{Secrets::KMS_KEYRING_NAME} \
      --key #{encryption_key} \
      --primary --format json
    }

    begin
      new_version = JSON.parse(new_version)
      new_version_id = get_crypto_key_version(new_version["name"])
    rescue
      debug_output "ERROR: Unable to create new version for key '#{encryption_key}', terminating!", new_version
      raise
    end

    return new_version_id
  end

  # This method disables all versions except primary for target encryption_key
  def disable_non_primary_key_versions(encryption_key, primary_version_id)
    puts "[secret-mgmt] Retrieving versions for key '#{encryption_key}' to disable..."
    key_versions = %x{
      gcloud kms keys versions list \
      --location #{@infra_region} \
      --keyring #{Secrets::KMS_KEYRING_NAME} \
      --key #{encryption_key} \
      --format json
    }

    begin
      key_versions = JSON.parse(key_versions)
    rescue
      debug_output "ERROR: Unable to retrieve versions for key '#{encryption_key}', terminating!", key_versions
      raise
    end

    key_versions.each do |version|
      version_id = get_crypto_key_version(version["name"])
      next if version["state"] != "ENABLED" or version_id == primary_version_id

      puts "[secret-mgmt] Disabling version #{version_id} for key '#{encryption_key}'..."
      version_disabled = %x{
        gcloud kms keys versions disable #{version_id} \
        --location #{@infra_region} \
        --keyring #{Secrets::KMS_KEYRING_NAME} \
        --key #{encryption_key} \
        --format json
      }

      begin
        version_disabled = JSON.parse(version_disabled)
        raise unless version_disabled['state'] == "DISABLED"
      rescue
        debug_output "ERROR: Unable to disable version #{version_id} for key '#{encryption_key}', terminating!", version_disabled
        raise
      end
    end
  end

  # This method destroys disabled versions except N latest versions_to_keep for target encryption_key
  def destroy_disabled_non_primary_key_versions(encryption_key, versions_to_keep = 10)
    puts "[secret-mgmt] Retrieving disabled versions for key '#{encryption_key}' to destroy..."
    key_versions = %x{
      gcloud kms keys versions list \
      --location #{@infra_region} \
      --keyring #{Secrets::KMS_KEYRING_NAME} \
      --key #{encryption_key} \
      --filter=state=DISABLED \
      --sort-by=~createTime \
      --format json
    }

    begin
      key_versions = JSON.parse(key_versions)
    rescue
      debug_output "ERROR: Unable to retrieve versions for key '#{encryption_key}', terminating!", key_versions
      raise
    end

    key_versions.each do |version|
      version_id = get_crypto_key_version(version["name"])
      if versions_to_keep > 0
        puts "[secret-mgmt] Skipping version #{version_id}, because need to keep #{versions_to_keep} most recent disabled versions!"
        versions_to_keep = versions_to_keep - 1
        next
      end

      puts "[secret-mgmt] Destroying version #{version_id} for key '#{encryption_key}'..."
      version_destroyed = %x{
        gcloud kms keys versions destroy #{version_id} \
        --location #{@infra_region} \
        --keyring #{Secrets::KMS_KEYRING_NAME} \
        --key #{encryption_key} \
        --format json
      }

      begin
        version_destroyed = JSON.parse(version_destroyed)
        raise unless version_destroyed['state'] == "DESTROY_SCHEDULED"
      rescue
        debug_output "ERROR: Unable to destroy version #{version_id} for key '#{encryption_key}', terminating!", version_destroyed
        raise
      end
    end
  end

  # This method returns KMS key version number from path:
  # PATH: `projects/gpii-gcp-dev-tyler/locations/global/keyRings/keyring/cryptoKeys/default/cryptoKeyVersions/1`
  def get_crypto_key_version(path)
    return path.match(/\/([0-9]+)$/)[1]
  end

  # This method outputs error message and api response
  def debug_output(message, api_response = '')
    puts
    puts message
    puts
    if api_response
      puts "Response from API was:"
      puts api_response
      puts
    end
  end
end


# vim: et ts=2 sw=2:
