#!/usr/bin/env ruby


require "docker-api"
require "yaml"

class SyncImages

  CONFIG_FILE = "./versions.yml"
  REGISTRY_URL = "gcr.io/gpii2test-common-stg"

  def self.load_config()
    return YAML.load(File.read(SyncImages::CONFIG_FILE))
  end

  def self.process_config(config)
    config.keys.sort.each do |component|
      image_name = config[component]["image"]
      sha = self.process_image(component, image_name)
      config[component]["sha"] = sha
    end
    self.write_new_config(config)
  end

  def self.process_image(component, image_name)
    image = self.pull_image(image_name)
    sha = self.get_sha_from_image(image)
    new_image_name = self.retag_image(image, image_name)
    self.push_image(image, new_image_name)

    return sha
  end

  def self.pull_image(image_name)
    puts "Pulling #{image_name}..."
    image = Docker::Image.create("fromImage" => image_name)
    return image
  end

  def self.get_sha_from_image(image)
    sha = image.info["RepoDigests"][0]
    puts "Got image with sha #{sha}..."
    return sha
  end

  def self.retag_image(image, image_name)
    new_image_name = "#{SyncImages::REGISTRY_URL}/#{image_name}"
    puts "Retagging #{image_name} as #{new_image_name}..."
    image.tag("repo" => new_image_name)
    return new_image_name
  end

  def self.push_image(image, new_image_name)
    puts "Pushing #{new_image_name}..."
    image.push(nil, "repo_tag" => new_image_name)
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
