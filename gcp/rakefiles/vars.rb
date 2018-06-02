class Vars
  def self.set_vars(env)
    if ENV["TF_VAR_project_id"].nil?
      if ["stg", "prd"].include?(env)
        ENV["TF_VAR_project_id"] = "gpii-#{env}"
      else
        puts "  ERROR: TF_VAR_project_id must be set!"
        puts "  Do this: export TF_VAR_project_id=<your name>-<env>"
        puts "  and try again."
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
