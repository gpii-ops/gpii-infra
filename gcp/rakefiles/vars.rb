class Vars
  def self.set_vars(env)
    if ENV["TF_VAR_project_id"].nil?
      if ["dev"].include?(env)
        if ENV["USER"].nil?
          puts "  ERROR: USER must be set!"
          puts "  Do this: export USER=<your name>"
          puts "  and try again."
          raise ArgumentError, "USER must be set"
        end
        ENV["TF_VAR_project_id"] = "gpii-#{env}-#{ENV["USER"]}"
      elsif ["stg", "prd"].include?(env)
        ENV["TF_VAR_project_id"] = "gpii-#{env}"
      else
        puts "  ERROR: TF_VAR_project_id must be set!"
        puts "  Usually, this value will be calculated for you, but you are"
        puts "  using an env I don't recognize: #{env}."
        puts "  Either pick a different env or, if you know what you're doing,"
        puts "  you may override TF_VAR_project_id directly:"
        puts "    export TF_VAR_project_id=<env>-<your name>"
        puts "  Do one of those and try again."
        raise ArgumentError, "TF_VAR_project_id must be set"
      end
    end
    ENV["ENV"] = env
    if ENV["ORGANIZATION_ID"].nil?
      ENV["ORGANIZATION_ID"] = "247149361674"  # RtF Organization
    end
    if ENV["BILLING_ID"].nil?
      ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F"  # RtF Billing Account
    end
  end
end

# vim: et ts=2 sw=2:
