#!/usr/bin/env ruby


require "yaml"

class SyncImages

  CONFIG_FILE = "./versions.yml"

  def self.load_config()
    return YAML.load(File.read(SyncImages::CONFIG_FILE))
  end

  def self.process_config(config)
    config.keys.each do |component|
      self.process_image(component, config[component]["image"])
    end
  end

  def self.process_image(component, image)
    puts "component: #{component}. image: #{image}."
  end

end


def main()
  config = SyncImages.load_config()
  SyncImages.process_config(config)
end


# vim: et ts=2 sw=2:
