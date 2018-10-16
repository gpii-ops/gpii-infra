require "json"
require "google/cloud/monitoring"

@project_id = ENV['PROJECT_ID']
@destroy_triggered = ENV['DESTROY']
@resource_dir="#{File.expand_path(File.dirname(__FILE__))}/resources_rendered"

def get_notification_channel_attribute(notification_channel)
  if notification_channel["labels"]["email_address"]
    result = notification_channel["labels"]["email_address"]
  end

  return result
end

def get_uptime_check_attribute(uptime_check)
  if uptime_check["display_name"]
    result = uptime_check["display_name"]
  end

  return result
end

def get_alert_policy_attribute(alert_policy)
  if alert_policy["display_name"]
    result = alert_policy["display_name"]
  end

  return result
end

def process_notification_channels(notification_channels = [])
  notification_channel_service_client = Google::Cloud::Monitoring::NotificationChannel.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::NotificationChannelServiceClient.project_path(@project_id)

  stackdriver_notification_channels = {}
  processed_notification_channels = {}

  notification_channel_service_client.list_notification_channels(formatted_parent).each do |notification_channel|
    stackdriver_notification_channels[get_notification_channel_attribute(notification_channel)] = notification_channel
  end

  notification_channels.each do |notification_channel|
    notification_channel = JSON.parse(notification_channel)
    notification_channel_attribute = get_notification_channel_attribute(notification_channel)

    if stackdriver_notification_channels[notification_channel_attribute]
      notification_channel["name"] = stackdriver_notification_channels[notification_channel_attribute]["name"]
      puts "Updating notification channel \"#{notification_channel_attribute}\"..."
      notification_channel_service_client.update_notification_channel(notification_channel)
    else
      puts "Creating notification channel \"#{notification_channel_attribute}\"..."
      notification_channel = notification_channel_service_client.create_notification_channel(formatted_parent, notification_channel)
    end

    processed_notification_channels[notification_channel_attribute] = notification_channel["name"]
  end

  stackdriver_notification_channels.each do |name, notification_channel|
    notification_channel_attribute = get_notification_channel_attribute(notification_channel)

    unless processed_notification_channels.include? notification_channel_attribute
      puts "Deleting notification channel \"#{notification_channel_attribute}\"..."
      notification_channel_service_client.delete_notification_channel(notification_channel["name"])
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
    stackdriver_uptime_checks[get_uptime_check_attribute(uptime_check)] = uptime_check
  end

  uptime_checks.each do |uptime_check|
    uptime_check = JSON.parse(uptime_check)
    uptime_check_attribute = get_uptime_check_attribute(uptime_check)

    if stackdriver_uptime_checks[uptime_check_attribute]
      uptime_check["name"] = stackdriver_uptime_checks[uptime_check_attribute]["name"]
      puts "Updating uptime check \"#{uptime_check_attribute}\"..."
      uptime_check_service_client.update_uptime_check_config(uptime_check)
    else
      puts "Creating uptime check \"#{uptime_check_attribute}\"..."
      uptime_check = uptime_check_service_client.create_uptime_check_config(formatted_parent, uptime_check)
    end

    processed_uptime_checks[uptime_check_attribute] = uptime_check["name"]
  end


  stackdriver_uptime_checks.each do |name, uptime_check|
    uptime_check_attribute = get_uptime_check_attribute(uptime_check)

    unless processed_uptime_checks.include? uptime_check_attribute
      puts "Deleting uptime check \"#{uptime_check_attribute}\"..."
      uptime_check_service_client.delete_uptime_check_config(uptime_check["name"])
    end
  end

  return processed_uptime_checks
end

def process_alert_policies(alert_policies = [])
  alert_policy_service_client = Google::Cloud::Monitoring::AlertPolicy.new(version: :v3)
  formatted_parent = Google::Cloud::Monitoring::V3::AlertPolicyServiceClient.project_path(@project_id)

  stackdriver_alert_policies = {}
  processed_alert_policies = {}

  alert_policy_service_client.list_alert_policies(formatted_parent).each do |alert_policy|
    stackdriver_alert_policies[get_alert_policy_attribute(alert_policy)] = alert_policy
  end


  alert_policies.each do |alert_policy|
    alert_policy = JSON.parse(alert_policy)
    alert_policy_attribute = get_alert_policy_attribute(alert_policy)
    alert_policy["notification_channels"] = @processed_notification_channels.values

    if stackdriver_alert_policies[alert_policy_attribute]
      alert_policy["name"] = stackdriver_alert_policies[alert_policy_attribute]["name"]
      puts "Updating alert policy \"#{alert_policy_attribute}\"..."
      alert_policy_service_client.update_alert_policy(alert_policy)
    else
      puts "Creating alert policy \"#{alert_policy_attribute}\"..."
      alert_policy = alert_policy_service_client.create_alert_policy(formatted_parent, alert_policy)
    end

    processed_alert_policies[alert_policy_attribute] = alert_policy["name"]
  end


  stackdriver_alert_policies.each do |name, alert_policy|
    alert_policy_attribute = get_alert_policy_attribute(alert_policy)

    unless processed_alert_policies.include? alert_policy_attribute
      puts "Deleting alert policy \"#{alert_policy_attribute}\"..."
      alert_policy_service_client.delete_alert_policy(alert_policy["name"])
    end
  end

  return processed_alert_policies
end

unless @destroy_triggered
  Dir.chdir(@resource_dir)
  resource_types = Dir.glob("*").select {|r| File.directory? r}
  resources = {}

  resource_types.each do |resource_type|
    resources[resource_type] = []
    Dir.glob("#{resource_type}/*").each do |resource|
      resources[resource_type] << File.read("#{@resource_dir}/#{resource}")
    end
  end

  @processed_notification_channels = process_notification_channels(resources["notification_channels"])
  process_uptime_checks(resources["uptime_checks"])
  process_alert_policies(resources["alert_policies"])
else
  process_alert_policies
  process_uptime_checks
  process_notification_channels
end
