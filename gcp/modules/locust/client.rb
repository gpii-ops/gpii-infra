require "csv"
require "json"
require "google/cloud/monitoring"

module LocustClient

  @project_id = ENV['PROJECT_ID']

  def self.collect_metrics(all_stats, all_distributions, user_count)
    metrics = {}

    metrics["user_count"] = user_count

    stats = all_stats["stats"].select do |stat|
      stat["name"] == "Total"
    end

    stats = stats.first
    ["median_response_time", "min_response_time", "max_response_time",
     "avg_response_time", "num_failures", "num_requests", "current_rps"].each do |metric|
      metrics[metric] = stats[metric]
    end

    distributions = all_distributions.select do |dist|
      dist.include? "Total"
    end

    # Only add distributions if we actually have any
    unless distributions.empty?
      distributions = distributions.reverse.first
      ["100th_percentile", "99th_percentile", "98th_percentile", "95th_percentile", "90th_percentile",
       "80th_percentile", "75th_percentile", "66th_percentile", "50th_percentile"].each do |metric|
        metrics[metric] = distributions.pop
      end
    end

    return metrics
  end

  def self.process_locust_result(locust_stats_file, locust_distribution_file, app_name, user_count)
    all_stats = JSON.parse(File.read(locust_stats_file))
    all_distributions = CSV.parse(File.read(locust_distribution_file))
    collected_metrics = collect_metrics(all_stats, all_distributions, user_count)

    metric_service_client = Google::Cloud::Monitoring::Metric.new(version: :v3)
    formatted_name = Google::Cloud::Monitoring::V3::MetricServiceClient.project_path(@project_id)

    time_series = []
    time = Time.now.to_i

    collected_metrics.each do |metric, value|

      time_series << {
        "metric" => {
          "type" => "custom.googleapis.com/locust.io/#{app_name}/#{metric}",
        },
        "resource" => {
          "type" => "global",
          "labels" => {
            "project_id" => "#{@project_id}"
          }
        },
        "metric_kind" => "GAUGE",
        "value_type" => "DOUBLE",
        "points" => [
          {
            "interval" => {
              "end_time" => {
                "seconds" => time,
                "nanos" => 0
              }
            },
            "value" => {
              "double_value" => value.to_f
            }
          }
        ]
      }
    end

    begin
      metric_service_client.create_time_series(formatted_name, time_series)
    rescue Google::Gax::RetryError => err
      puts "[ERROR]: Error while submitting metrics to Stackdriver (Google::Gax::RetryError)."
      puts err.message
      exit 120
    end
  end
end


# vim: set et ts=2 sw=2:
