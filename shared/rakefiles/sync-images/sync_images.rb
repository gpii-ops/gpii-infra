#!/usr/bin/env ruby


require "docker-api"
require "yaml"

class SyncImages

  CONFIG_FILE = "./versions.yml"
  CREDS_FILE = "./creds.json"
  REGISTRY_URL = "gcr.io/gpii2test-common-stg"

  def self.load_config()
    return YAML.load(File.read(SyncImages::CONFIG_FILE))
  end

  def self.login()
    puts "Logging in with credentials from #{SyncImages::CREDS_FILE}..."
    creds = File.read(SyncImages::CREDS_FILE)
    Docker.authenticate!(
      "username" => "_json_key",
      "password" => creds,
      "serveraddress" => "https://gcr.io",
    )
  end

  def self.process_config(config)
    config.keys.sort.each do |component|
      image_name = config[component]["upstream_image"]
      (new_image_name, sha, tag) = self.process_image(component, image_name)
      config[component]["image"] = new_image_name
      config[component]["sha"] = sha
      config[component]["tag"] = tag
    end
    self.write_new_config(config)
  end

  def self.process_image(component, image_name)
    image = self.pull_image(image_name)
    new_image_name = self.retag_image(image, image_name)
    new_image_name_without_tag, tag = Docker::Util.parse_repo_tag(new_image_name)
    sha = self.get_sha_from_image(image, new_image_name_without_tag)
    self.push_image(image, new_image_name)

    return [new_image_name_without_tag, sha, tag]
  end

  def self.pull_image(image_name)
    puts "Pulling #{image_name}..."
    image = Docker::Image.create({"fromImage" => image_name}, creds: {})
    return image
  end

  def self.get_sha_from_image(image, image_name_without_tag)
    sha = nil
    image.info["RepoDigests"].each do |digest|
      digest_image, digest_sha = digest.split('@')
      if digest_image == image_name_without_tag
        sha = digest_sha
        break
      end
    end
    unless sha
      raise ArgumentError, "Could not find sha! image.info was #{image.info}"
    end
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
    # Docker.push collects output from the API call via 'response_block()', a
    # kind of callback function. Docker.push ignores errors and discards
    # output, though the output is available to a block passed to Docker.push.
    # Hence, we use a block to look for errors and explode if we find one.
    image.push(nil, repo_tag: new_image_name) do |output_line|
      puts "...output from push: #{output_line}"
      if output_line.include? '"error":'
        raise ArgumentError, "Found error message in output (see above)!"
      end
    end
  end

  def self.write_new_config(config)
    File.open(CONFIG_FILE, "w") do |f|
      f.write(YAML.dump(config))
    end
  end

end


def main()
  config = SyncImages.load_config()
  SyncImages.login()
  SyncImages.process_config(config)
end


# vim: et ts=2 sw=2:
