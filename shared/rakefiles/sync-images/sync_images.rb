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
      image_name = config[component]["image"]
      ###image.info["Config"]["Image"]
      sha = self.process_image(component, image_name)
      config[component]["sha"] = sha
    end
    self.write_new_config(config)
  end

  def self.process_image(component, image_name)
    image = self.pull_image(image_name)
    sha = self.get_sha_from_image(image)
    self.retag_image(image)
    self.push_image(image)

    return sha
  end

  def self.pull_image(image_name)
    puts "Pulling #{image_name}..."
    image = Docker::Image.create("fromImage" => image_name)
    return image
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
