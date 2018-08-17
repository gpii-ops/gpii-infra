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

  it "set_vars requires ENV['USER'] when env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "dev"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "USER must be set")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "fakecorp-#{project_type}-#{env}-fake-user")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=stg" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "fakecorp-#{project_type}-#{env}")
  end

  it "set_vars requires ENV['TF_VAR_project_id'] for unknown values of env" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return(nil)
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "fake-env"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "TF_VAR_project_id must be set")
  end

  it "set_vars calculates ENV['dns_(zones|records)'] when env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_zones", %Q|{ dev-gcp-corp-es = "fake-user.dev.gcp.corp.es." }|)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_records", %Q|{ dev-gcp-corp-es = "*.fake-user.dev.gcp.corp.es." }|)
  end

  it "set_vars doesn't clobber ENV['dns_(zones|records)'] when already set and env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_zones").and_return("fake-custom-dns-zone.")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_records").and_return("fake-custom-dns-record.")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_dns_zones", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_dns_records", any_args)
  end

  it "set_vars sets default vars" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return(nil)
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return(nil)
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("ENV", env)
    expect(ENV).to have_received(:[]=).with("TF_VAR_env", env)
    expect(ENV).to have_received(:[]=).with("ORGANIZATION_ID", "247149361674")
    expect(ENV).to have_received(:[]=).with("BILLING_ID", "01A0E1-B0B31F-349F4F")
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_name", "gpii")
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_domain", "gpii.net")
  end

  it "set_vars sets default vars for billing and organization" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_organization_id", "fake-organization-id")
    expect(ENV).to have_received(:[]=).with("TF_VAR_billing_id", "fake-billing-id")
  end

  it "set_vars doesn't clobber vars that are already set (even when env=stg)" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_name").and_return("fakecorp")
    allow(ENV).to receive(:[]).with("TF_VAR_organization_domain").and_return("corp.es")
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_project_id", any_args)
    expect(ENV).not_to have_received(:[]=).with("ORGANIZATION_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("BILLING_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_organization_name", any_args)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_organization_domain", any_args)
  end

  it "set_vars sets TF_VAR_nonce" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_nonce", a_value)
  end

  it "Create directory path" do
    allow(Dir).to receive(:mkdir).and_return("a", "b", "c", "d")
    allow(File).to receive(:directory).and_return(true)
    Vars.create_directory_if_not_exists("a/b/c/d")
    expect(Dir).to have_received(:mkdir).with("a/")
    expect(Dir).to have_received(:mkdir).with("a/b/")
    expect(Dir).to have_received(:mkdir).with("a/b/c/")
    expect(Dir).to have_received(:mkdir).with("a/b/c/d/")
  end
end


# vim: set et ts=2 sw=2:
