require "./sync_images.rb"

describe SyncImages do

  # It is not necessary or desirable to test File.read or YAML.load, but this
  # validates some plumbing.
  it "load_config returns parsed yaml" do
    fake_yaml = "foo: bar"
    allow(File).to receive(:read).with(SyncImages::CONFIG_FILE).and_return(fake_yaml)

    expected = {"foo" => "bar"}
    actual = SyncImages.load_config()
    expect(actual).to eq(expected)
  end

end


# vim: set et ts=2 sw=2:
