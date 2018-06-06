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
    env = "dev"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "USER must be set")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "gpii-#{project_type}-#{env}-fake-user")
  end

  it "set_vars calculates ENV['TF_VAR_project_id'] when env=stg" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_project_id", "gpii-#{project_type}-#{env}")
  end

  it "set_vars requires ENV['TF_VAR_project_id'] for unknown values of env" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return(nil)
    env = "fake-env"
    project_type = "fake-project-type"
    expect { Vars.set_vars(env, project_type) }.to raise_error(ArgumentError, "TF_VAR_project_id must be set")
  end

  it "set_vars calculates ENV['dns_(zones|records)'] when env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    env = "dev"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_zones", %Q|{ dev-gcp-gpii-net = "fake-user.dev.gcp.gpii.net." }|)
    expect(ENV).to have_received(:[]=).with("TF_VAR_dns_records", %Q|{ dev-gcp-gpii-net = "*.fake-user.dev.gcp.gpii.net." }|)
  end

  it "set_vars doesn't clobber ENV['dns_(zones|records)'] when already set and env=dev" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("USER").and_return("fake-user")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_zones").and_return("fake-custom-dns-zone.")
    allow(ENV).to receive(:[]).with("TF_VAR_dns_records").and_return("fake-custom-dns-record.")
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
    env = "fake-env"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).to have_received(:[]=).with("ENV", env)
    expect(ENV).to have_received(:[]=).with("ORGANIZATION_ID", "247149361674")
    expect(ENV).to have_received(:[]=).with("BILLING_ID", "01A0E1-B0B31F-349F4F")
  end

  it "set_vars doesn't clobber vars that are already set (even when env=stg)" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    env = "stg"
    project_type = "fake-project-type"
    Vars.set_vars(env, project_type)
    expect(ENV).not_to have_received(:[]=).with("TF_VAR_project_id", any_args)
    expect(ENV).not_to have_received(:[]=).with("ORGANIZATION_ID", any_args)
    expect(ENV).not_to have_received(:[]=).with("BILLING_ID", any_args)
  end
end


# vim: set et ts=2 sw=2:
