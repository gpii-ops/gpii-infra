require "securerandom"
require "yaml"
require "json"
require 'base64'

class Secrets

  KMS_KEYRING = "keyring"
  KMS_KEY = "default"

  SECRETS = [
    'couchdb_admin_username',
    'couchdb_admin_password',
    'couchdb_secret'
  ]

  GCLOUD_API = "https://www.googleapis.com"
  KMS_API = "https://cloudkms.googleapis.com"

  def self.populate_secrets()
    secrets = {}
    Secrets::SECRETS.each do |secret|
      unless ENV[secret.upcase].to_s.empty?
        secrets[secret] = ENV[secret.upcase]
      end
      if secrets[secret].to_s.empty?
        secrets[secret] = SecureRandom.hex
      end
      ENV["TF_VAR_#{secret}"] = secrets[secret]
    end

    return secrets
  end

  def self.get_secrets()
    @gs_bucket = "#{ENV['TF_VAR_project_id']}-#{Secrets::KMS_KEY}-secrets"
    @gs_secrets_file = "#{@gs_bucket}/o/secrets.yml"

    puts "[secrets] Checking if secrets file is present in GS bucket..."
    gs_secrets = %x{
      #{$exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X GET \"#{Secrets::GCLOUD_API}/storage/v1/b/#{@gs_secrets_file}\"'
    }

    begin
      gs_secrets = JSON.parse(gs_secrets)
    rescue
      puts "  ERROR: Unable to parse Google API response, terminating!"
      raise JSON::ParserError, "Unable to parse GS secrets file data"
    end

    # Encrypted secrets file not present in GS bucket
    # Populating secrets, encrypting them and uploading into GS
    if gs_secrets['error'] && gs_secrets['error']['code'] == 404
      secrets = set_secrets()
    # Encrypted secrets file is present, attempting to download and decrypt
    else
      puts "[secrets] Retrieving encrypted secrets from GS bucket..."
      gs_secrets = %x{
        #{$exekube_cmd} sh -c 'curl -s \
        -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
        -X GET \"#{Secrets::GCLOUD_API}/storage/v1/b/#{@gs_secrets_file}?alt=media\"'
      }

      gs_secrets = YAML.load(gs_secrets)
      if !gs_secrets['ciphertext']
        puts "  ERROR: Unable to parse Google API response, terminating!"
        raise IOError, "Unable to extract ciphertext from YAML data"
      end

      puts "[secrets] Decrypting secrets with KMS cert..."
      decrypted_secrets = %x{
        #{$exekube_cmd} sh -c 'curl -s \
        -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
        -H \"Content-Type:application/json\" \
        -X POST \"#{Secrets::KMS_API}/v1/projects/#{ENV['TF_VAR_project_id']}/locations/global/keyRings/#{Secrets::KMS_KEYRING}/cryptoKeys/#{Secrets::KMS_KEY}:decrypt\" \
        -d \"{\\\"ciphertext\\\":\\\"#{gs_secrets['ciphertext']}\\\"}\"'
      }

      begin
        decrypted_secrets = JSON.parse(decrypted_secrets)
        decrypted_secrets = Base64.decode64(decrypted_secrets['plaintext'])
        decrypted_secrets = JSON.parse(decrypted_secrets)
      rescue
        puts "  ERROR: Unable to parse Google API response, terminating!"
        raise JSON::ParserError, "Unable to parse secrets data"
      end

      puts "[secrets] Populating secrets..."
      decrypted_secrets.each do |key, val|
        ENV[key.upcase] = val
      end

      secrets = populate_secrets()
    end

    return secrets
  end

  def self.set_secrets()
    puts "Populating secrets..."
    secrets = populate_secrets()
    encoded_secrets = Base64.encode64(secrets.to_json).delete!("\n")

    puts "[secrets] Encrypting generated secrets with KMS cert..."
    encrypted_secrets = %x{
      #{$exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -H \"Content-Type:application/json\" \
      -X POST \"#{Secrets::KMS_API}/v1/projects/#{ENV['TF_VAR_project_id']}/locations/global/keyRings/#{Secrets::KMS_KEYRING}/cryptoKeys/#{Secrets::KMS_KEY}:encrypt\" \
      -d \"{\\\"plaintext\\\":\\\"#{encoded_secrets}\\\"}\"'
    }

    begin
      encrypted_secrets = JSON.parse(encrypted_secrets)
    rescue
      puts "  ERROR: Unable to parse Google API response, terminating!"
      raise JSON::ParserError, "Unable to parse GS secrets file data"
    end

    encrypted_secrets = {
      'ciphertext' => encrypted_secrets['ciphertext']
    }.to_yaml

    puts "[secrets] Uploading encrypted secrets into GS bucket..."
    gs_upload = %x{
      #{$exekube_cmd} sh -c 'curl -s \
      -H \"Authorization:Bearer $(gcloud auth print-access-token)\" \
      -X POST \"#{Secrets::GCLOUD_API}/upload/storage/v1/b/#{@gs_bucket}/o?uploadType=media&name=secrets.yml\" \
      -d \"#{encrypted_secrets}\"'
    }

    begin
      gs_upload = JSON.parse(gs_upload)
    rescue
      puts "  ERROR: Unable to parse Google API response, Terminating!"
      raise JSON::ParserError, "Unable to upload secrets file into GS"
    end

    return secrets
  end
end
