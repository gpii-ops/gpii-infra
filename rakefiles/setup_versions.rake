require "yaml"

task :setup_versions do
  version_yml = File.read("../modules/deploy/version.yml")
  @versions = YAML.load(version_yml)
end
