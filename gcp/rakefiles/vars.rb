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

    ENV["TF_VAR_organization_name"] = "gpii" if ENV["TF_VAR_organization_name"].nil?

    ENV["TF_VAR_organization_domain"] = "gpii.net" if ENV["TF_VAR_organization_domain"].nil?

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

    if ["dev"].include?(env)
      zone = "#{ENV["USER"]}.#{env}.gcp.#{ENV["TF_VAR_organization_domain"]}."
      if ENV["TF_VAR_dns_zones"].nil?
        ENV["TF_VAR_dns_zones"] = %Q|{ #{env}-gcp-#{ENV["TF_VAR_organization_domain"].tr('.','-')} = "#{zone}" }|
      end
      if ENV["TF_VAR_dns_records"].nil?
        ENV["TF_VAR_dns_records"] = %Q|{ #{env}-gcp-#{ENV["TF_VAR_organization_domain"].tr('.','-')} = "*.#{zone}" }|
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
  def self.create_directory_if_not_exists(path)
    recursive = path.split('/')
    directory = ''
    recursive.each do |sub_directory|
      directory += sub_directory + '/'
      Dir.mkdir(directory) unless (File.directory? directory)
    end
  end
end

# vim: et ts=2 sw=2:
