require "json"
require "google/cloud/monitoring"
require "google/cloud/logging"

@project_id = ENV['PROJECT_ID']

if ENV['STACKDRIVER_DEBUG']
  @debug_mode = true unless ENV['STACKDRIVER_DEBUG'].empty?
end

def apply_resources
  resources = read_resources
  processed_log_based_metrics = process_log_based_metrics(resources["log_based_metrics"])
  processed_notification_channels = process_notification_channels(resources["notification_channels"])
  process_uptime_checks(resources["uptime_checks"])
  process_alert_policies(resources["alert_policies"], processed_notification_channels)
end

def destroy_resources
  process_alert_policies
  process_uptime_checks
  process_notification_channels
  process_log_based_metrics
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
  end

  return result
end

def get_uptime_check_identifier(uptime_check)
  if uptime_check["display_name"]
    result = uptime_check["display_name"]
  end

  return result
end

def get_alert_policy_identifier(alert_policy)
  if alert_policy["display_name"]
    result = alert_policy["display_name"]
  end

  return result
end

def debug_output(resource)
  return resource.to_hash.to_json
end

def process_log_based_metrics(log_based_metrics = [])
  stackdriver_logging_client = Google::Cloud::Logging.new(project_id: @project_id)

  stackdriver_log_based_metrics = {}
  processed_log_based_metrics = {}

  stackdriver_logging_client.metrics.each do |log_based_metric|
    puts "[DEBUG] log_based_metric: " + log_based_metric.inspect if @debug_mode
    stackdriver_log_based_metrics[log_based_metric.name] = log_based_metric
  end

  log_based_metrics.each do |log_based_metric|
    if stackdriver_log_based_metrics[log_based_metric["name"]]
      puts "Updating log-based metric \"#{log_based_metric["name"]}\"..."
      metric = stackdriver_logging_client.metric log_based_metric["name"]
      metric.filter = log_based_metric["filter"]
      metric.save
    else
      puts "Creating log-based metric \"#{log_based_metric["name"]}\"..."
      stackdriver_logging_client.create_metric log_based_metric["name"], log_based_metric["filter"]
    end

    processed_log_based_metrics[log_based_metric["name"]] = log_based_metric
  end

  stackdriver_log_based_metrics.each do |name, log_based_metric|
    unless processed_log_based_metrics.include? name
      if @debug_mode
        puts "[DEBUG] Skipping deletion of log-based metric \"#{name}\"..."
      else
        puts "Deleting log-based metric \"#{name}\"..."
        metric = stackdriver_logging_client.metric name
        metric.delete
      end
    end
  end

  return processed_log_based_metrics
end

def process_notification_channels(notification_channels = [])
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
      puts "Updating notification channel \"#{notification_channel_identifier}\"..."
      notification_channel_service_client.update_notification_channel(notification_channel)
    else
      puts "Creating notification channel \"#{notification_channel_identifier}\"..."
      notification_channel = notification_channel_service_client.create_notification_channel(formatted_parent, notification_channel)
    end

    processed_notification_channels[notification_channel_identifier] = notification_channel["name"]
  end

  stackdriver_notification_channels.each do |name, notification_channel|
    notification_channel_identifier = get_notification_channel_identifier(notification_channel)

    unless processed_notification_channels.include? notification_channel_identifier
      if @debug_mode
        puts "[DEBUG] Skipping deletion of notification channel \"#{notification_channel_identifier}\"..."
      else
        puts "Deleting notification channel \"#{notification_channel_identifier}\"..."
        notification_channel_service_client.delete_notification_channel(notification_channel["name"])
      end
    end
  end

  return processed_notification_channels
end

def process_uptime_checks(uptime_checks = [])
  uptime_check_service_client = Google::Cloud::Monitoring::UptimeCheck.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::UptimeCheckServiceClient.project_path(@project_id)

  stackdriver_uptime_checks = {}
  processed_uptime_checks = {}

  uptime_check_service_client.list_uptime_check_configs(formatted_parent).each do |uptime_check|
    puts "[DEBUG] uptime_check: " + debug_output(uptime_check) if @debug_mode
    stackdriver_uptime_checks[get_uptime_check_identifier(uptime_check)] = uptime_check
  end

  uptime_checks.each do |uptime_check|
    uptime_check_identifier = get_uptime_check_identifier(uptime_check)

    if stackdriver_uptime_checks[uptime_check_identifier]
      uptime_check["name"] = stackdriver_uptime_checks[uptime_check_identifier]["name"]
      puts "Updating uptime check \"#{uptime_check_identifier}\"..."
      uptime_check_service_client.update_uptime_check_config(uptime_check)
    else
      puts "Creating uptime check \"#{uptime_check_identifier}\"..."
      uptime_check = uptime_check_service_client.create_uptime_check_config(formatted_parent, uptime_check)
    end

    processed_uptime_checks[uptime_check_identifier] = uptime_check["name"]
  end


  stackdriver_uptime_checks.each do |name, uptime_check|
    uptime_check_identifier = get_uptime_check_identifier(uptime_check)

    unless processed_uptime_checks.include? uptime_check_identifier
      if @debug_mode
        puts "[DEBUG] Skipping deletion of uptime check \"#{uptime_check_identifier}\"..."
      else
        puts "Deleting uptime check \"#{uptime_check_identifier}\"..."
        uptime_check_service_client.delete_uptime_check_config(uptime_check["name"])
      end
    end
  end

  return processed_uptime_checks
end

def process_alert_policies(alert_policies = [], notification_channels = {})
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
    alert_policy["notification_channels"] = notification_channels.values

    if stackdriver_alert_policies[alert_policy_identifier]
      alert_policy["name"] = stackdriver_alert_policies[alert_policy_identifier]["name"]
      puts "Updating alert policy \"#{alert_policy_identifier}\"..."
      alert_policy_service_client.update_alert_policy(alert_policy)
    else
      puts "Creating alert policy \"#{alert_policy_identifier}\"..."
      alert_policy = alert_policy_service_client.create_alert_policy(formatted_parent, alert_policy)
    end

    processed_alert_policies[alert_policy_identifier] = alert_policy["name"]
  end


  stackdriver_alert_policies.each do |name, alert_policy|
    alert_policy_identifier = get_alert_policy_identifier(alert_policy)

    unless processed_alert_policies.include? alert_policy_identifier
      if @debug_mode
        puts "[DEBUG] Skipping deletion of alert policy \"#{alert_policy_identifier}\"..."
      else
        puts "Deleting alert policy \"#{alert_policy_identifier}\"..."
        alert_policy_service_client.delete_alert_policy(alert_policy["name"])
      end
    end
  end

  return processed_alert_policies
end
