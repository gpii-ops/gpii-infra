require "../vars.rb"

describe Vars do
  it "set_vars requires ENV['TF_VAR_project_id']" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return(nil)
    expect { Vars.set_vars() }.to raise_error(ArgumentError, "TF_VAR_project_id must be set")
  end

  it "set_vars sets default vars" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    Vars.set_vars()
    expect(ENV).to have_received(:[]=).with("ENV", "dev")
    expect(ENV).to have_received(:[]=).with("ORGANIZATION_ID", "247149361674")
    expect(ENV).to have_received(:[]=).with("BILLING_ID", "01A0E1-B0B31F-349F4F")
  end

  it "set_vars doesn't clobber vars that are already set" do
    allow(ENV).to receive(:[]=)
    allow(ENV).to receive(:[]).with("TF_VAR_project_id").and_return("fake-project-id")
    allow(ENV).to receive(:[]).with("ENV").and_return("fake-env")
    allow(ENV).to receive(:[]).with("ORGANIZATION_ID").and_return("fake-organization-id")
    allow(ENV).to receive(:[]).with("BILLING_ID").and_return("fake-billing-id")
    Vars.set_vars()
    expect(ENV).not_to have_received(:[]=)
  end
end

# vim: set et ts=2 sw=2:
