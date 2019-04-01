require "yaml"

class SyncImages

  CONFIG_FILE = "./versions.yml"

  def self.load_config()
    return YAML.load(File.read(SyncImages::CONFIG_FILE))
  end

end


# vim: et ts=2 sw=2:
