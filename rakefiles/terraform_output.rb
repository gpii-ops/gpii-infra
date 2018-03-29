require "json"
require_relative "./wait_for.rb"

def terraform_output(dir, tmpdir)
  args = [dir, tmpdir]
  return wait_for(
    args,
    run_with: method(:terraform_output_runner),
    sleep_secs: 3,
    max_wait_secs: 9,
    verbose: true,
  )
end

def terraform_output_runner(dir, tmpdir, &block)
  terraform_cmd = "cd #{dir} && TMPDIR=#{tmpdir} terragrunt output-all --terragrunt-non-interactive -json --terragrunt-ignore-dependency-errors"
  terraform_cmd_output = `#{terraform_cmd}`
  terraform_cmd_ok = $?
  if terraform_cmd_ok != 0
    raise "terraform_output failed with return code #{terraform_cmd_ok}. Terraform output was:\n#{terraform_cmd_output}\n"
  end

  jq_cmd = "echo '#{terraform_cmd_output}' | jq -s add"
  jq_cmd_output = `#{jq_cmd}`
  jq_ok = $?
  if jq_ok == 0
    block.call(jq_ok, JSON.parse(jq_cmd_output))
  else
    raise "terraform_output failed with return code #{jq_ok}. Terraform output was:\n#{terraform_cmd_output}\njq output was:\n#{jq_cmd_output}\n"
  end
end
