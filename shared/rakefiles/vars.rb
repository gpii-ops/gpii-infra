require "securerandom"
require "yaml"

class Vars

  VERSIONS_FILE = "../../../common/versions.yml"

  def self.set_vars(env, project_type)
    if ["prd"].include?(env)
      if ENV["RAKE_REALLY_RUN_IN_PRD"].nil?
        puts "  ERROR: Tried to run in env 'prd' but RAKE_REALLY_RUN_IN_PRD is not set"
        raise ArgumentError, "Tried to run in env 'prd' but RAKE_REALLY_RUN_IN_PRD is not set"
      end
    end

    ENV["ENV"] = ENV["TF_VAR_env"] = env

    ENV["TF_VAR_organization_name"] = "gpii" if ENV["TF_VAR_organization_name"].nil?

    ENV["TF_VAR_organization_domain"] = "gpii.net" if ENV["TF_VAR_organization_domain"].nil?

    ENV["ORGANIZATION_ID"] = "247149361674" if ENV["ORGANIZATION_ID"].nil? # RtF Organization
    ENV["TF_VAR_organization_id"] = ENV["ORGANIZATION_ID"]

    ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F" if ENV["BILLING_ID"].nil? # RtF Billing Account
    ENV["TF_VAR_billing_id"] = ENV["BILLING_ID"]

    @domain_name = "#{env}.gcp.#{ENV["TF_VAR_organization_domain"]}"
    if ["dev"].include?(env)
      if ENV["USER"].nil?
        puts "  ERROR: USER must be set!"
        puts "  Do this: export USER=<your name>"
        puts "  and try again."
        raise ArgumentError, "USER must be set"
      end
      @domain_name = "#{ENV["USER"]}.#{@domain_name}"
    end

    ENV["TF_VAR_dns_zones"] = %Q|{ #{@domain_name.tr('.','-')} = "#{@domain_name}." }| if ENV["TF_VAR_dns_zones"].nil?

    ENV["TF_VAR_dns_records"] = %Q|{ #{@domain_name.tr('.','-')} = "*.#{@domain_name}." }| if ENV["TF_VAR_dns_records"].nil?

    ENV["TF_VAR_domain_name"] = @domain_name #i.e doe.dev.gcp.gpii.net

    # Hack to force Terraform to reapply some resources on every run
    ENV["TF_VAR_nonce"] = SecureRandom.hex

    if ENV["TF_VAR_project_id"].nil?
      if ["dev"].include?(env)
        ENV["TF_VAR_project_id"] = "#{ENV["TF_VAR_organization_name"]}-#{project_type}-#{env}-#{ENV["USER"]}"
      elsif ["stg", "prd"].include?(env)
        ENV["TF_VAR_project_id"] = "#{ENV["TF_VAR_organization_name"]}-#{project_type}-#{env}"
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
  end

  def self.set_versions()
    versions = YAML.load(File.read(Vars::VERSIONS_FILE))
    ['flowmanager', 'preferences', 'dataloader'].each do |component|
      next unless versions["gpii-#{component}"]
      ENV["TF_VAR_#{component}_repository"] = versions["gpii-#{component}"].split('@')[0]
      ENV["TF_VAR_#{component}_checksum"] = versions["gpii-#{component}"].split('@')[1]
    end
  end
end

# vim: et ts=2 sw=2:
