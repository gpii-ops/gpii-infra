# This file contains Stackdriver Ruby client implementation
# It is used by modules like: gcp-stackdriver-alerting, gcp-stackdriver-lbm

require "json"
require "google/cloud/monitoring"
require "google/cloud/logging"

@project_id = ENV['PROJECT_ID']

if ENV['STACKDRIVER_DEBUG']
  @debug_mode = true unless ENV['STACKDRIVER_DEBUG'].empty?
end

# This method looks for resource types in resources hash that
# read_resources generates, and invokes apply methods in proper order.
# Each apply method returns array with orphaned (not described in configs)
# resources that is later passed to destroy_resources method for deletion.
def apply_resources(resources)
  orphaned_resources = {}

  begin
    orphaned_resources["log_based_metrics"] = apply_log_based_metrics(resources["log_based_metrics"]) if resources["log_based_metrics"]
    orphaned_resources["notification_channels"], processed_notification_channels = apply_notification_channels(resources["notification_channels"]) if resources["notification_channels"]
    orphaned_resources["alert_policies"] = apply_alert_policies(resources["alert_policies"], processed_notification_channels) if resources["alert_policies"]
  rescue Google::Gax::RetryError
    puts "[ERROR]: Deadline exceeded while applying resources!"
    exit 120
  end

  destroy_resources(orphaned_resources, true)
end

# We may want to destroy resources in two cases:
# 1. During Terraform module destruction – all resources.
# 2. After resource application – only orphaned (not described in configs)
#    resources, to ensure that current Stackdriver state matches with the state that
#    described by configuration primitives. In this case destroy_orphaned_only
#    variable must be set to true, and resources_to_destroy must contain
#    Stackdriver hash with:
#      { "resource_type" => [array with orphaned resource names] }
def destroy_resources(resources_to_destroy, destroy_orphaned_only = false)
  begin
    destroy_alert_policies(resources_to_destroy["alert_policies"], destroy_orphaned_only) if resources_to_destroy.include? "alert_policies"
    destroy_notification_channels(resources_to_destroy["notification_channels"], destroy_orphaned_only) if resources_to_destroy.include? "notification_channels"
    destroy_log_based_metrics(resources_to_destroy["log_based_metrics"], destroy_orphaned_only) if resources_to_destroy.include? "log_based_metrics"
  rescue Google::Gax::RetryError
    puts "[ERROR]: Deadline exceeded while destroying resources!"
    exit 120
  end
end

def read_resources(resource_dir = "")
  resource_dir = "#{File.expand_path(File.dirname(__FILE__))}/resources_rendered" if resource_dir.empty?
  resources = {}

  Dir.chdir(resource_dir) do
    resource_types = Dir.glob("*").select {|r| File.directory? r}
    resource_types.each do |resource_type|
      resources[resource_type] = []
      Dir.glob("#{resource_type}/*").each do |resource|
        resources[resource_type] << JSON.parse(File.read("#{resource_dir}/#{resource}"))
      end
    end
  end

  return resources
end

def get_notification_channel_identifier(notification_channel)
  if notification_channel["labels"]["email_address"]
    result = notification_channel["labels"]["email_address"]
  elsif notification_channel["labels"]["channel_name"]
    result = notification_channel["labels"]["channel_name"]
  end

  return result
end

def get_alert_policy_identifier(alert_policy)
  if alert_policy["display_name"]
    result = alert_policy["display_name"]
  end

  return result
end

def compare_alert_policies(stackdriver_alert_policy, alert_policy)
  stackdriver_alert_policy = JSON.parse(stackdriver_alert_policy.to_h.to_json)
  ["name", "creation_record", "mutated_by", "mutation_record"]. each do |attribute|
    stackdriver_alert_policy.delete(attribute)
  end
  stackdriver_alert_policy.delete("documentation") if stackdriver_alert_policy["documentation"] == nil
  stackdriver_alert_policy["conditions"].each do |condition|
    condition.delete("name")
    condition.delete("condition_absent") if condition["condition_absent"] == nil
    condition.delete("condition_threshold") if condition["condition_threshold"] == nil
  end

  policy_changed = (stackdriver_alert_policy != alert_policy)
  if @debug_mode and policy_changed
    puts "[DEBUG] alert policy has changed. Old:"
    puts debug_output(alert_policy)
    puts "New:"
    puts debug_output(stackdriver_alert_policy)
  end

  return policy_changed
end

def compare_notification_channels(stackdriver_notification_channel, notification_channel)
  stackdriver_notification_channel = JSON.parse(stackdriver_notification_channel.to_h.to_json)

  return stackdriver_notification_channel != notification_channel
end

def debug_output(resource)
  return JSON.pretty_generate(resource.to_h)
end

def apply_log_based_metrics(log_based_metrics = [])
  stackdriver_logging_client = Google::Cloud::Logging.new(project_id: @project_id)

  stackdriver_log_based_metrics = {}
  processed_log_based_metrics = {}

  stackdriver_logging_client.metrics.each do |log_based_metric|
    puts "[DEBUG] log_based_metric: " + log_based_metric.inspect if @debug_mode
    stackdriver_log_based_metrics[log_based_metric.name] = log_based_metric
  end

  log_based_metrics.each do |log_based_metric|
    if stackdriver_log_based_metrics[log_based_metric["name"]]
      if stackdriver_log_based_metrics[log_based_metric["name"]].filter != log_based_metric["filter"]
        puts "Updating log-based metric \"#{log_based_metric["name"]}\"..."
        metric = stackdriver_logging_client.metric log_based_metric["name"]
        metric.filter = log_based_metric["filter"]
        metric.save
      else
        puts "Log-based metric \"#{log_based_metric["name"]}\" is up-to-date..."
      end
    else
      puts "Creating log-based metric \"#{log_based_metric["name"]}\"..."
      stackdriver_logging_client.create_metric log_based_metric["name"], log_based_metric["filter"]
    end

    processed_log_based_metrics[log_based_metric["name"]] = log_based_metric
  end

  orphaned_resources = []
  stackdriver_log_based_metrics.each do |name, log_based_metric|
    unless processed_log_based_metrics.include? name
      orphaned_resources << log_based_metric.name
    end
  end

  return orphaned_resources
end

def apply_notification_channels(notification_channels = [])
  notification_channel_service_client = Google::Cloud::Monitoring::NotificationChannel.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::NotificationChannelServiceClient.project_path(@project_id)

  stackdriver_notification_channels = {}
  processed_notification_channels = {}

  notification_channel_service_client.list_notification_channels(formatted_parent).each do |notification_channel|
    puts "[DEBUG] notification_channel: " + debug_output(notification_channel) if @debug_mode
    stackdriver_notification_channels[get_notification_channel_identifier(notification_channel)] = notification_channel
  end

  notification_channels.each do |notification_channel|
    notification_channel_identifier = get_notification_channel_identifier(notification_channel)

    if stackdriver_notification_channels[notification_channel_identifier]
      notification_channel["name"] = stackdriver_notification_channels[notification_channel_identifier]["name"]
      unless notification_channel["type"] == "slack"
        if compare_notification_channels(stackdriver_notification_channels[notification_channel_identifier], notification_channel)
          puts "Updating notification channel \"#{notification_channel_identifier}\"..."
          notification_channel_service_client.update_notification_channel(notification_channel)
        else
          puts "Notification channel \"#{notification_channel_identifier}\" is up-to-date..."
        end
      else
        puts "Skipping update of immutable notification channel \"#{notification_channel_identifier}\"..."
      end
    else
      unless notification_channel["type"] == "slack"
        puts "Creating notification channel \"#{notification_channel_identifier}\"..."
        notification_channel = notification_channel_service_client.create_notification_channel(formatted_parent, notification_channel)
      else
        puts "Skipping creation of immutable notification channel \"#{notification_channel_identifier}\"..."
      end
    end

    processed_notification_channels[notification_channel_identifier] = notification_channel["name"] if notification_channel["name"]
  end

  orphaned_resources = []
  stackdriver_notification_channels.each do |name, notification_channel|
    notification_channel_identifier = get_notification_channel_identifier(notification_channel)

    unless processed_notification_channels.include? notification_channel_identifier
      orphaned_resources << notification_channel.name
    end
  end

  return orphaned_resources, processed_notification_channels
end

def apply_alert_policies(alert_policies = [], notification_channels = {})
  alert_policy_service_client = Google::Cloud::Monitoring::AlertPolicy.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::AlertPolicyServiceClient.project_path(@project_id)

  stackdriver_alert_policies = {}
  processed_alert_policies = {}

  alert_policy_service_client.list_alert_policies(formatted_parent).each do |alert_policy|
    puts "[DEBUG] alert_policy: " + debug_output(alert_policy) if @debug_mode
    stackdriver_alert_policies[get_alert_policy_identifier(alert_policy)] = alert_policy
  end

  alert_policies.each do |alert_policy|
    alert_policy_identifier = get_alert_policy_identifier(alert_policy)
    alert_policy["notification_channels"] = notification_channels.values if notification_channels.values

    if stackdriver_alert_policies[alert_policy_identifier]
      if compare_alert_policies(stackdriver_alert_policies[alert_policy_identifier], alert_policy)
        alert_policy["name"] = stackdriver_alert_policies[alert_policy_identifier]["name"]
        puts "Updating alert policy \"#{alert_policy_identifier}\"..."
        alert_policy_service_client.update_alert_policy(alert_policy)
      else
        puts "Alert policy \"#{alert_policy_identifier}\" is up-to-date..."
      end
    else
      puts "Creating alert policy \"#{alert_policy_identifier}\"..."
      alert_policy = alert_policy_service_client.create_alert_policy(formatted_parent, alert_policy)
    end

    processed_alert_policies[alert_policy_identifier] = alert_policy["name"]
  end

  orphaned_resources = []
  stackdriver_alert_policies.each do |name, alert_policy|
    alert_policy_identifier = get_alert_policy_identifier(alert_policy)

    unless processed_alert_policies.include? alert_policy_identifier
      orphaned_resources << alert_policy.name
    end
  end

  return orphaned_resources
end

def destroy_alert_policies(resources_to_destroy = [], destroy_orphaned_only = false)
  alert_policy_service_client = Google::Cloud::Monitoring::AlertPolicy.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::AlertPolicyServiceClient.project_path(@project_id)
  alert_policy_service_client.list_alert_policies(formatted_parent).each do |alert_policy|
    if not destroy_orphaned_only or resources_to_destroy.include?(alert_policy.name)
      alert_policy_identifier = get_alert_policy_identifier(alert_policy)

      if @debug_mode
        puts "[DEBUG] Skipping deletion of alert policy \"#{alert_policy_identifier}\"..."
      else
        puts "Deleting alert policy \"#{alert_policy_identifier}\"..."
        alert_policy_service_client.delete_alert_policy(alert_policy.name)
      end
    end
  end
end

def destroy_uptime_checks(resources_to_exclude = [])
  uptime_check_service_client = Google::Cloud::Monitoring::UptimeCheck.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::UptimeCheckServiceClient.project_path(@project_id)

  uptime_check_service_client.list_uptime_check_configs(formatted_parent).each do |uptime_check|
    if not resources_to_exclude.include?(uptime_check.name)
      if @debug_mode
        puts "[DEBUG] Skipping deletion of uptime check \"#{uptime_check.name}\"..."
      else
        puts "Deleting uptime check \"#{uptime_check.name}\"..."
        uptime_check_service_client.delete_uptime_check_config(uptime_check.name)
      end
    end
  end
end

def destroy_notification_channels(resources_to_destroy = [], destroy_orphaned_only = false)
  notification_channel_service_client = Google::Cloud::Monitoring::NotificationChannel.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::NotificationChannelServiceClient.project_path(@project_id)
  notification_channel_service_client.list_notification_channels(formatted_parent).each do |notification_channel|
    if not destroy_orphaned_only or resources_to_destroy.include?(notification_channel.name)
      notification_channel_identifier = get_notification_channel_identifier(notification_channel)

      if @debug_mode
        puts "[DEBUG] Skipping deletion of notification channel \"#{notification_channel_identifier}\"..."
      elsif notification_channel["type"] == "slack"
        puts "Skipping deletion of immutable notification channel \"#{notification_channel_identifier}\"..."
      else
        puts "Deleting notification channel \"#{notification_channel_identifier}\"..."
        notification_channel_service_client.delete_notification_channel(notification_channel.name)
      end
    end
  end
end

def destroy_log_based_metrics(resources_to_destroy = [], destroy_orphaned_only = false)
  stackdriver_logging_client = Google::Cloud::Logging.new(project_id: @project_id)
  stackdriver_logging_client.metrics.each do |log_based_metric|
    if not destroy_orphaned_only or resources_to_destroy.include?(log_based_metric.name)
      if @debug_mode
        puts "[DEBUG] Skipping deletion of log-based metric \"#{log_based_metric.name}\"..."
      else
        puts "Deleting log-based metric \"#{log_based_metric.name}\"..."
        metric = stackdriver_logging_client.metric log_based_metric.name
        metric.delete
      end
    end
  end
end
