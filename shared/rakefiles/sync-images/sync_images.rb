#!/usr/bin/env ruby


require "docker-api"
require "yaml"

class SyncImages

  CONFIG_FILE = "./versions.yml"

  def self.load_config()
    return YAML.load(File.read(SyncImages::CONFIG_FILE))
  end

  def self.process_config(config)
    config.keys.sort.each do |component|
      image = config[component]["image"]
      sha = self.process_image(component, image)
      config[component]["sha"] = sha
    end
    self.write_new_config(config)
  end

  def self.process_image(component, image)
    self.pull_image(image)
    sha = self.get_sha_from_image(image)
    self.retag_image(image)
    self.push_image(image)

    return sha
  end

  def self.pull_image(image)
    puts "pulling #{image}"
  end

  def self.write_new_config(config)
    File.open(CONFIG_FILE, "w") do |f|
      f.write(YAML.dump(config))
    end
  end

end


def main()
  config = SyncImages.load_config()
  SyncImages.process_config(config)
end


# vim: et ts=2 sw=2:
