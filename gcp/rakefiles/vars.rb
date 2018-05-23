class Vars
  def self.set_vars
    if ENV["TF_VAR_project_id"].nil?
      puts "  ERROR: TF_VAR_project_id must be set!"
      puts "  Do this: export TF_VAR_project_id=<your name>-<env>"
      puts "  and try again."
      raise ArgumentError, "TF_VAR_project_id must be set"
    end
    if ENV["ENV"].nil?
      ENV["ENV"] = "dev"
    end
    ENV["ORGANIZATION_ID"] = "247149361674"  # RtF Organization
    ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F"  # RtF Billing Account
  end
end

# vim: set et ts=2 sw=2:
