require "../secrets.rb"

describe Secrets do

  it "new instance accepts project_id" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)
    expect(secrets.project_id).to eq(fake_project_id)
  end

  it "new instance accepts infra_region" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)
    expect(secrets.infra_region).to eq(fake_infra_region)
  end

  it "new instance accepts decrypt_with_global_key" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    decrypt_with_global_key = true
    secrets = Secrets.new(fake_project_id, fake_infra_region, decrypt_with_global_key=decrypt_with_global_key)
    expect(secrets.infra_region).to eq(fake_infra_region)
  end

  it "get_decrypt_url constructs a url" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)

    fake_encryption_key = "fake_encryption_key"
    actual = secrets.get_decrypt_url(fake_encryption_key)
    expected = "#{Secrets::GOOGLE_KMS_API}/v1/projects/#{fake_project_id}/locations/#{fake_infra_region}/keyRings/#{Secrets::KMS_KEYRING_NAME}/cryptoKeys/#{fake_encryption_key}:decrypt"
    expect(actual).to eq(expected)
  end

end


# vim: set et ts=2 sw=2:
