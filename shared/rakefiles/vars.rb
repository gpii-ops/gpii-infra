require "securerandom"
require "yaml"

class Vars

  VERSIONS_FILE = "../../../shared/versions.yml"

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

    ENV["TF_VAR_common_project_id"] = "gpii-common-prd" if ENV["TF_VAR_common_project_id"].nil?

    ENV["ORGANIZATION_ID"] = "247149361674" if ENV["ORGANIZATION_ID"].nil? # RtF Organization
    ENV["TF_VAR_organization_id"] = ENV["ORGANIZATION_ID"]

    ENV["BILLING_ID"] = "01A0E1-B0B31F-349F4F" if ENV["BILLING_ID"].nil? # RtF Billing Account
    ENV["TF_VAR_billing_id"] = ENV["BILLING_ID"]

    ENV["BILLING_ORGANIZATION_ID"] = "247149361674" if ENV["BILLING_ORGANIZATION_ID"].nil? # RtF Organization that owns Billing Account

    ENV["TF_VAR_infra_region"] = "us-central1" if ENV["TF_VAR_infra_region"].nil? # GCP region to deploy cluster and other resources

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

    # Set HELM TLS variables
    ENV["HELM_TLS_CERT"]    = "/project/live/#{env}/secrets/kube-system/helm-tls/helm.cert.pem"
    ENV["HELM_TLS_KEY"]     = "/project/live/#{env}/secrets/kube-system/helm-tls/helm.key.pem"
    ENV["HELM_TLS_CA_CERT"] = "/project/live/#{env}/secrets/kube-system/helm-tls/ca.cert.pem"
    ENV["HELM_TLS_ENABLE"]  = "true"
    ENV["HELM_TLS_VERIFY"]  = "true"

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
    versions.each do |component, values|
      next unless (values["generated"] and
                   values["generated"]["repository"] and
                   values["generated"]["sha"] and
                   values["generated"]["tag"])
      ENV["TF_VAR_#{component}_repository"] = values["generated"]["repository"]
      ENV["TF_VAR_#{component}_checksum"] = values["generated"]["sha"]
      # Usually, the yaml library can deduce that a tag is a string. However, if
      # the tag is a valid float it is imported as such. Then,
      # ENV[component_tag]= raises "TypeError: no implicit conversion of Float
      # into String".
      ENV["TF_VAR_#{component}_tag"] = values["generated"]["tag"].to_s
    end
  end
end

# vim: et ts=2 sw=2:
