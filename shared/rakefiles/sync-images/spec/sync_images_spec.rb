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

  it "process_config calls process_image on each image" do
    fake_config = {
      "dataloader" => {
        "image" => "gpii/universal:latest",
      },
      "flowmanager" => {
        "image" => "gpii/universal:latest",
      },
    }

    allow(SyncImages).to receive(:process_image)
    allow(SyncImages).to receive(:write_new_config)

    SyncImages.process_config(fake_config)

    expect(SyncImages).to have_received(:process_image).with("dataloader", "gpii/universal:latest")
    expect(SyncImages).to have_received(:process_image).with("flowmanager", "gpii/universal:latest")
  end

  it "process_config writes new config" do
    # Keys are out of lexical order to test that they get sorted at the end
    # (and thus get the shas in the right order).
    fake_config = {
      "flowmanager" => {
        "image" => "gpii/universal:latest",
      },
      "dataloader" => {
        "image" => "gpii/universal:latest",
      },
    }
    fake_sha_1 = "sha256:c0ffee"
    fake_sha_2 = "sha256:50da"
    expected_config = {
      "dataloader" => {
        "image" => "gpii/universal:latest",
        "sha" => fake_sha_1,
      },
      "flowmanager" => {
        "image" => "gpii/universal:latest",
        "sha" => fake_sha_2,
      },
    }

    allow(SyncImages).to receive(:process_image).and_return(fake_sha_1, fake_sha_2)
    allow(SyncImages).to receive(:write_new_config)

    SyncImages.process_config(fake_config)

    expect(SyncImages).to have_received(:write_new_config).with(expected_config)
  end

  it "process_image calls helpers on image" do
    fake_component = "fake_component"
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_image = "fake_org/fake_img:fake_tag"
    fake_sha = "sha256:c0ffee"

    allow(SyncImages).to receive(:pull_image)
    allow(SyncImages).to receive(:get_sha_from_image).and_return(fake_sha)
    allow(SyncImages).to receive(:retag_image)
    allow(SyncImages).to receive(:push_image)

    actual = SyncImages.process_image(fake_component, fake_image_name)

    expect(SyncImages).to have_received(:pull_image).with(fake_image_name)
###    expect(SyncImages).to have_received(:get_sha_from_image).with(fake_image)
###    expect(SyncImages).to have_received(:retag_image).with(fake_image)
###    expect(SyncImages).to have_received(:push_image).with(fake_image)
###    expect(actual).to eq(fake_sha)
  end

  it "pull_image pulls image" do
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_image = "fake docker image object"
    allow(Docker::Image).to receive(:create).and_return(fake_image)
    actual = SyncImages.pull_image(fake_image_name)
    expect(actual).to eq(fake_image)
    expect(Docker::Image).to have_received(:create).with({"fromImage" => fake_image_name})
  end

  it "get_sha_from_image gets sha" do
    class FakeImage
      attr_accessor :info
    end
    fake_sha = "sha256:c0ffee"
    fake_image = FakeImage.new
    fake_image.info = {
      "RepoDigests" => [
        "sha256:c0ffee",
      ]
    }
    actual = SyncImages.get_sha_from_image(fake_image)
    expect(actual).to eq(fake_sha)
  end

  # It is not necessary or desirable to test File.write or YAML.dump, but this
  # validates some plumbing.
  it "write_new_config dumps and writes yaml" do
    fake_config = {
      "foo" => "bar",
    }
    buffer = StringIO.new()
    allow(File).to receive(:open).and_yield(buffer)
    SyncImages.write_new_config(fake_config)
    expect(buffer.string).to eq("---\nfoo: bar\n")
  end

end


# vim: set et ts=2 sw=2: