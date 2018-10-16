variable "domain_name" {}
variable "project_id" {}
variable "serviceaccount_key" {}

resource "template_dir" "resources" {
  source_dir      = "${path.cwd}/resources/stackdriver"
  destination_dir = "${path.cwd}/resources_rendered"

  vars {
    project_id  = "${var.project_id}"
    domain_name = "${var.domain_name}"
  }
}

data "external" "resources" {
  depends_on = ["template_dir.resources"]
  program    = [
    "ruby",
    "-e",
    <<EOF
      #!/usr/bin/ruby

      require 'json'

      @resource_dir="${path.cwd}/resources_rendered"

      Dir.chdir(@resource_dir)
      resource_types = Dir.glob("*").select {|r| File.directory? r}
      result = {}

      resource_types.each do |resource_type|
        result[resource_type] = []
        Dir.glob("#{resource_type}/*").each do |resource|
          result[resource_type] << File.read("#{@resource_dir}/#{resource}")
        end
        result[resource_type] = result[resource_type].to_json
      end

      puts result.to_json
    EOF
    ,
  ]
}

data "template_file" "stackdriver_client" {
  template = "${file("${path.cwd}/resources/client.rb")}"

  vars {
    project_id            = "${var.project_id}"
    serviceaccount_key    = "${var.serviceaccount_key}"
    notification_channels = "${lookup(data.external.resources.result, "notification_channels", "")}"
    alert_policies        = "${lookup(data.external.resources.result, "alert_policies", "")}"
    uptime_checks         = "${lookup(data.external.resources.result, "uptime_checks", "")}"
  }
}

resource "local_file" "stackdriver_client" {
    content  = "${data.template_file.stackdriver_client.rendered}"
    filename = "${path.cwd}/resources_rendered/client.rb"
}
