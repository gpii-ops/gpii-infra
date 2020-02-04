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

  it "new instance accepts decrypt_with_key_from_region" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    decrypt_with_key_from_region = "jupiter-south2"
    secrets = Secrets.new(fake_project_id, fake_infra_region, decrypt_with_key_from_region=decrypt_with_key_from_region)
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

  it "get_decrypt_url uses global when @decrypt_with_key_from_region is set" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    decrypt_with_key_from_region = "jupiter-south2"
    secrets = Secrets.new(fake_project_id, fake_infra_region, decrypt_with_key_from_region=decrypt_with_key_from_region)

    fake_encryption_key = "fake_encryption_key"
    actual = secrets.get_decrypt_url(fake_encryption_key)
    expected = "#{Secrets::GOOGLE_KMS_API}/v1/projects/#{fake_project_id}/locations/#{decrypt_with_key_from_region}/keyRings/#{Secrets::KMS_KEYRING_NAME}/cryptoKeys/#{fake_encryption_key}:decrypt"
    expect(actual).to eq(expected)
  end

  it "collect_secrets returns empty hash when SECRETS_CONFIG dne" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)

    allow(File).to receive(:file?).with(Secrets::SECRETS_CONFIG).and_return(false)
    secrets.collect_secrets()
    actual = secrets.collected_secrets
    expected = {}
    expect(actual).to eq(expected)
  end

  it "set_secrets raises if collect_secrets not called" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)

    expect { secrets.set_secrets() }.to raise_error(RuntimeError, "Called set_secrets() without first calling collect_secrets()")
  end

  it "populate_secrets populates secrets correctly" do
    fake_project_id = "fakeorg-fakecloud-fakeenv-fakeuser"
    fake_infra_region = "mars-north1"
    secrets = Secrets.new(fake_project_id, fake_infra_region)
    secrets.populate_secrets(["secret_foo", "key_bar", "uuid_baz"])

    expect(ENV["TF_VAR_secret_foo"].length).to be(32)
    expect(ENV["TF_VAR_uuid_baz"].length).to be(36)

    expect {
      decipher = OpenSSL::Cipher::AES.new(256, :CBC)
      decipher.decrypt
      decipher.key = Base64.strict_decode64(ENV["TF_VAR_key_bar"])
    }.not_to raise_error
  end

end


# vim: set et ts=2 sw=2:
