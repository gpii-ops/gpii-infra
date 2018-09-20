# This function obfuscates sensitive data in the output of a command, relying on @secrets.
# In case target command terminates with non-zero exit status, it will exit() with the same
# status, preventing further rake execution, unless exit_on_nonzero_status is set to false.
def sh_filter(cmd, exit_on_nonzero_status = true)
  process = IO.popen(cmd).each do |out|
    # After switching back to helm-release, plaintext certificates and keys may be present in output
    out.gsub!(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----\\n/m, "<SENSITIVE>")
    out.gsub!(/-----BEGIN EC PRIVATE KEY-----.*?-----END EC PRIVATE KEY-----\\n/m, "<SENSITIVE>")
    if @secrets
      # Secrets are grouped by encryption key, i.e. {'key1' => ['secret1', 'secret2']}
      @secrets.each do |encryption_key, secrets_array|
        secrets_array.each do |secret|
          out.gsub!(/#{Regexp.escape(ENV["TF_VAR_#{secret}"])}/, "<SENSITIVE>") if ENV["TF_VAR_#{secret}"].size > 0
        end
      end
    end
    puts out
  end
  exit_status = Process.waitpid2(process.pid)[1].exitstatus
  if exit_status != 0 and exit_on_nonzero_status
    puts "Command '#{cmd}' terminated with exit status #{exit_status}!"
    exit exit_status
  end
end
