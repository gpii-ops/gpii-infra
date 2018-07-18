# Obfuscate sensitive data in the output of a command, relying on @secrets
def sh_filter(*cmd)
  IO.popen(*cmd).each do |out|
    # After switching back to helm-release, plaintext certificates and keys may be present in output
    out.gsub!(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----\\n/m, "<SENSITIVE>")
    out.gsub!(/-----BEGIN EC PRIVATE KEY-----.*?-----END EC PRIVATE KEY-----\\n/m, "<SENSITIVE>")
    if @secrets
      # Secrets are grouped by encryption key, i.e. {'key1' => ['secret1', 'secret2']}
      @secrets.each do |encryption_key, secrets_array|
        secrets_array.each do |secret|
          out.gsub!(Regexp.escape(ENV["TF_VAR_#{secret}"]), "<SENSITIVE>")
        end
      end
    end
    puts out
  end
end
