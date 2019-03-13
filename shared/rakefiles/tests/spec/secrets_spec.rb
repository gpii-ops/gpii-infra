require "../secrets.rb"

describe Secrets do

  it "new instance accepts project_name" do
    fake_project_name = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_name, fake_infra_region)
    expect(secrets.project_name).to eq(fake_project_name)
  end

  it "new instance uses project_name in kms_keyring_name" do
    fake_project_name = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_name, fake_infra_region)
    expect(secrets.kms_keyring_name).to include(fake_project_name)
  end

  it "new instance accepts infra_region" do
    fake_project_name = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_name, fake_infra_region)
    expect(secrets.infra_region).to eq(fake_infra_region)
  end

end


# vim: set et ts=2 sw=2:
