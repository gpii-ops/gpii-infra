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

    if ["dev"].include?(env)
      if ENV["USER"].nil?
        puts "  ERROR: USER must be set!"
        puts "  Do this: export USER=<your name>"
        puts "  and try again."
        raise ArgumentError, "USER must be set"
      end
    end

    if ENV["TF_VAR_project_id"].nil?
      if ["dev"].include?(env)
        ENV["TF_VAR_project_id"] = "gpii-#{project_type}-#{env}-#{ENV["USER"]}"
      elsif ["stg", "prd"].include?(env)
        ENV["TF_VAR_project_id"] = "gpii-#{project_type}-#{env}"
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

    if ["dev"].include?(env)
      zone = "#{ENV["USER"]}.#{env}.gcp.gpii.net"
      if ENV["TF_VAR_dns_zones"].nil?
        ENV["TF_VAR_dns_zones"] = %Q|{ #{env}-gcp-gpii-net = "#{zone}." }|
      end
      if ENV["TF_VAR_dns_records"].nil?
        ENV["TF_VAR_dns_records"] = %Q|{ #{env}-gcp-gpii-net = "*.#{zone}." }|
      end

      ENV["TF_VAR_domain_name"] = "#{zone}"
    end

    ENV["ENV"] = ENV["TF_VAR_env"] = env

    if ENV["ORGANIZATION_ID"].nil?
      ENV["ORGANIZATION_ID"] = "247149361674"  # RtF Organization
    end

    if ENV["BILLING_ID"].nil?
      ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F"  # RtF Billing Account
    end

    # Hack to force Terraform to reapply some resources on every run
    ENV["TF_VAR_nonce"] = SecureRandom.hex
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
