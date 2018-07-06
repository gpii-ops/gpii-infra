# Obfuscate sensitive data in the output of a command, relying on @secrets
def sh_filter(*cmd)
  IO.popen(*cmd).each do |out|
    # After switching back to helm-release, plaintext certificates and keys may be present in output
    out.gsub!(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----\\n/m, "<SENSITIVE>")
    out.gsub!(/-----BEGIN EC PRIVATE KEY-----.*?-----END EC PRIVATE KEY-----\\n/m, "<SENSITIVE>")
    if @secrets
      @secrets.each do |key, val|
        out.gsub!("#{Regexp.escape(val)}", "<SENSITIVE>")
      end
    end
    puts out
  end
end
