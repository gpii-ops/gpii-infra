require "yaml"

task :setup_versions, [:path_to_version_yml] do |taskname, args|
  args.with_defaults(path_to_version_yml: "../../../shared/versions.aws.yml")
  version_yml = File.read(args[:path_to_version_yml])
  @versions = YAML.load(version_yml)
end
