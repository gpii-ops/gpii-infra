require "../vars.rb"

describe Vars do
  # When there is a test failure involving ENV, rspec dumps the contents of ENV
  # (that is, the contents of all environment variables) into an error message,
  # and thus to the CI log, and thus to notification email. This could leak
  # credentials stored in the CI/CD environment. So, we scrub ENV before we
  # start testing.
  #
  # Note that this clobbers environment variables in the running test process.
  # It works today, but if the testing situation becomes more complex and weird
  # stuff is happening, this method might be why!
  def scrub_env
    ENV.each_key do |key|
      ENV.delete(key)
    end
  end

  before :all do
    scrub_env
  end

  before :each do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
  end

  it "set_vars requires ENV['RAKE_REALLY_RUN_IN_PRD'] when env=prd" do
    env = "prd"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "Tried to run in env 'prd' but RAKE_REALLY_RUN_IN_PRD is not set")
  end

  it "set_vars requires ENV['USER'] when env=dev" do
    env = "dev"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "USER must be set")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=dev" do
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("fake.org")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "fakecorp-#{project_type}-#{env}-fake-user")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=stg" do
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "fakecorp-#{project_type}-#{env}")
  end

  it "set_vars requires ENV['TF_VAR_project_id'] for unknown values of env" do
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return(nil)
    env = "fake-env"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "TF_VAR_project_id must be set")
  end

  it "set_vars calculates ENV['dns_(zones|records)'] when env=dev" do
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("fake.org")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_zones", %Q|{ fake-user-dev-gcp-fake-org = "fake-user.dev.gcp.fake.org." }|)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_records", %Q|{ fake-user-dev-gcp-fake-org = "*.fake-user.dev.gcp.fake.org." }|)
  end

  it "set_vars doesn't clobber ENV['dns_(zones|records)'] when already set and env=dev" do
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_zones").and_return("fake-custom-dns-zone.")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_records").and_return("fake-custom-dns-record.")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_dns_zones", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_dns_records", any_args)
  end

  it "set_vars sets ENV['TF_VAR_domain_name'] when env=dev" do
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("fake.org")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_domain_name", "fake-user.dev.gcp.fake.org")
  end

  it "set_vars sets default vars" do
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("ENV", env)
    expect(ENV).to have_received(:[]=).with("TF_VAR_env", env)
    expect(ENV).to have_received(:[]=).with("ORGANIZATION_ID", "247149361674")
    expect(ENV).to have_received(:[]=).with("BILLING_ORGANIZATION_ID", "247149361674")
    expect(ENV).to have_received(:[]=).with("BILLING_ID", "01A0E1-B0B31F-349F4F")
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_name", "gpii")
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_domain", "gpii.net")
    expect(ENV).to have_received(:[]=).with("TF_VAR_common_project_id", "gpii-common-prd")
    expect(ENV).to have_received(:[]=).with("TF_VAR_infra_region", "us-central1")
  end

  it "set_vars sets default vars for billing and organization" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ORGANIZATION_ID").and_return("fake-billing-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_id", "fake-organization-id")
    expect(ENV).to have_received(:[]=).with("TF_VAR_billing_id", "fake-billing-id")
  end

  it "set_vars doesn't clobber vars that are already set (even when env=stg)" do
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ORGANIZATION_ID").and_return("fake-billing-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("fake.org")
    allow(ENV).to receive(:[]).with("TF_VAR_common_project_id").and_return("fakecorp-common-stg")
    allow(ENV).to receive(:[]).with("TF_VAR_infra_region").and_return("fake-region1")
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_project_id", any_args)
    expect(ENV).not_to have_received(:[]=).with("ORGANIZATION_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("BILLING_ORGANIZATION_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("BILLING_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_organization_name", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_organization_domain", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_common_project_id", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_infra_region", any_args)
  end

  it "set_vars sets TF_VAR_nonce" do
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_nonce", a_value)
  end


  it "set_versions sets TF_VAR_<component>_(repository|checksum|tag)" do
    fake_versions = {
      "flowmanager" => {
        "upstream" => {
          "repository" => "fake_repository:fake_tag",
        },
        "generated" => {
          "repository" => "gcr.io/some-project/fake_repository",
          "sha" => "sha256:c0ffee",
          "tag" => "fake_tag",
        },
      },
      "component_without_generated" => {
        "upstream" => {
          "repository" => "another_fake_repository",
        },
      },
      "component_without_repository" => {
        "upstream" => {
          "repository" => "another_fake_repository",
        },
        "generated" => {
          "sha" => "sha256:50da",
          "tag" => "fake_tag",
        },
      },
      "component_without_sha" => {
        "upstream" => {
          "repository" => "another_fake_repository",
        },
        "generated" => {
          "repository" => "gcr.io/some-project/another_fake_repository",
          "tag" => "fake_tag",
        },
      },
      "component_without_tag" => {
        "upstream" => {
          "repository" => "another_fake_repository",
        },
        "generated" => {
          "repository" => "gcr.io/some-project/another_fake_repository",
          "sha" => "sha256:50da",
        },
      },
    }
    allow(File).to receive(:read)
    allow(YAML).to receive(:load).and_return(fake_versions)
    Vars.set_versions()
    expect(ENV).to have_received(:[]=).with("TF_VAR_flowmanager_repository", "gcr.io/some-project/fake_repository")
    expect(ENV).to have_received(:[]=).with("TF_VAR_flowmanager_checksum", "sha256:c0ffee")
    expect(ENV).to have_received(:[]=).with("TF_VAR_flowmanager_tag", "fake_tag")
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_component_without_repository_repository", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_component_without_sha_repository", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_component_without_tag_repository", any_args)
  end

  it "set_versions handles tags that look like floats" do
    # Usually, the yaml library can deduce that a tag is a string. However, if
    # the tag is a valid float it is imported as such. Then,
    # ENV[component_tag]= raises "TypeError: no implicit conversion of Float
    # into String".
    fake_tag = 3.9
    fake_versions = {
      "flowmanager" => {
        "upstream" => {
          "repository" => "fake_repository:fake_tag",
        },
        "generated" => {
          "repository" => "gcr.io/some-project/fake_repository",
          "sha" => "sha256:c0ffee",
          "tag" => fake_tag,
        },
      },
    }
    allow(File).to receive(:read)
    allow(YAML).to receive(:load).and_return(fake_versions)
    Vars.set_versions()
    expect(ENV).to have_received(:[]=).with("TF_VAR_flowmanager_tag", "#{fake_tag}")
  end

  it "set_vars sets Helm TLS variables" do
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    env = "xyz"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("HELM_TLS_CERT", "/project/live/#{env}/secrets/kube-system/helm-tls/helm.cert.pem")
    expect(ENV).to have_received(:[]=).with("HELM_TLS_KEY", "/project/live/#{env}/secrets/kube-system/helm-tls/helm.key.pem")
    expect(ENV).to have_received(:[]=).with("HELM_TLS_CA_CERT", "/project/live/#{env}/secrets/kube-system/helm-tls/ca.cert.pem")
    expect(ENV).to have_received(:[]=).with("HELM_TLS_ENABLE", "true")
    expect(ENV).to have_received(:[]=).with("HELM_TLS_VERIFY", "true")
  end
end

# vim: set et ts=2 sw=2:
