# Obfuscate sensitive data in the output of a command, relying on @secrets
def sh_filter(*cmd)
  if @secrets
    IO.popen(*cmd).each do |out|
      @secrets.each do |key, val|
        out = out.gsub("#{val}", "<SENSITIVE>")
      end
      puts out
    end
  else
    sh *cmd
  end
end
