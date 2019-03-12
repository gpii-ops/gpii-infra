require "../secrets.rb"

describe Secrets do

  it "new instance accepts project_name" do
    fake_project_name = "fakeorg-fakecloud-fakeenv-fakeuser"
    secrets = Secrets.new(fake_project_name)
    expect(secrets.project_name).to eq(fake_project_name)
  end

end


# vim: set et ts=2 sw=2:
