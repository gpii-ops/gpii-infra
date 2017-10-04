require "json"

def terraform_output(dir, tmpdir)
  cmd = "cd #{dir} && TMPDIR=#{tmpdir} terragrunt output-all --terragrunt-non-interactive -json --terragrunt-ignore-dependency-errors | jq -s add"
  res = `#{cmd}`
  ok = $?
  if ok == 0
    return JSON.parse(res)
  else
    raise "terraform_output failed with return code #{ok}. Output was:\n#{res}"
  end
end
