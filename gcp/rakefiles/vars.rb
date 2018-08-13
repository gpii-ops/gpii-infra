require "securerandom"
require "yaml"

class Vars

  # Hack to avoid changes in gpii-version-updater
  VERSION_FILE = "../../../aws/modules/deploy/version.yml"

  def self.set_vars(env, project_type)
    if ["dev"].include?(env)
      if ENV["USER"].nil?
        puts "  ERROR: USER must be set!"
        puts "  Do this: export USER=<your name>"
        puts "  and try again."
        raise ArgumentError, "USER must be set"
      end
    end


    if ENV["TF_VAR_project_name"].nil?
      if ["dev"].include?(env)
        ENV["TF_VAR_project_name"] = "gpii-#{project_type}-#{env}-#{ENV["USER"]}"
      elsif ["stg", "prd"].include?(env)
        ENV["TF_VAR_project_name"] = "gpii-#{project_type}-#{env}"
      else
        puts "  ERROR: TF_VAR_project_name must be set!"
        puts "  Usually, this value will be calculated for you, but you are"
        puts "  using an env I don't recognize: #{env}."
        puts "  Either pick a different env or, if you know what you're doing,"
        puts "  you may override TF_VAR_project_name directly:"
        puts "    export TF_VAR_project_name=<env>-<your name>"
        puts "  Do one of those and try again."
        raise ArgumentError, "TF_VAR_project_name must be set"
      end
    end

    if ENV["TF_VAR_project_id"].nil?
      project_id = `#{@exekube_cmd} gcloud projects list --format='value(project_id)' --filter='project_id ~ ^#{ENV["TF_VAR_project_name"]}-\d{4,4}'`
      if project_id.empty?
        nonce = rand.to_s[2..5]
        ENV["TF_VAR_project_id"] = "#{ENV["TF_VAR_project_name"]}-#{nonce}"
      else
        ENV["TF_VAR_project_id"] = project_id
      end
    end

    if ["dev"].include?(env)
      zone = "#{ENV["USER"]}.#{env}.gcp.gpii.net."
      if ENV["TF_VAR_dns_zones"].nil?
        ENV["TF_VAR_dns_zones"] = %Q|{ #{env}-gcp-gpii-net = "#{zone}" }|
      end
      if ENV["TF_VAR_dns_records"].nil?
        ENV["TF_VAR_dns_records"] = %Q|{ #{env}-gcp-gpii-net = "*.#{zone}" }|
      end
    end

    ENV["ENV"] = ENV["TF_VAR_env"] = env

    if ENV["ORGANIZATION_ID"].nil?
      ENV["ORGANIZATION_ID"] = "247149361674"  # RtF Organization
    end
    ENV["TF_VAR_organization_id"] = ENV["ORGANIZATION_ID"]

    if ENV["BILLING_ID"].nil?
      ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F"  # RtF Billing Account
    end
    ENV["TF_VAR_billing_id"] = ENV["BILLING_ID"]

    # Hack to force Terraform to reapply some resources on every run
    ENV["TF_VAR_nonce"] = SecureRandom.hex
  end

  def self.set_versions()
    versions = YAML.load(File.read(Vars::VERSION_FILE))
    if versions['flowmanager']
      ENV['TF_VAR_flowmanager_repository'] = versions['flowmanager'].split('@')[0]
      ENV['TF_VAR_flowmanager_checksum'] = versions['flowmanager'].split('@')[1]
    end
    if versions['preferences']
      ENV['TF_VAR_preferences_repository'] = versions['preferences'].split('@')[0]
      ENV['TF_VAR_preferences_checksum'] = versions['preferences'].split('@')[1]
    end
    if versions['gpii-dataloader']
      ENV['TF_VAR_dataloader_repository'] = versions['gpii-dataloader'].split('@')[0]
      ENV['TF_VAR_dataloader_checksum'] = versions['gpii-dataloader'].split('@')[1]
    end
  end
end

# vim: et ts=2 sw=2:
