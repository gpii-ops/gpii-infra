require "csv"
require "json"
require "google/cloud/monitoring"

@project_id = ENV['PROJECT_ID']

def process_locust_result(locust_stats_file, locust_distribution_file, app_name)

  metrics = {}
  all_stats = JSON.parse(File.read(locust_stats_file))

  metrics["user_count"] = all_stats["user_count"]

  stats = all_stats["stats"].select do |stat|
    stat["name"] == "Total"
  end

  stats = stats.first
  ["median_response_time", "min_response_time", "max_response_time",
   "avg_response_time", "num_failures", "num_requests", "current_rps"].each do |metric|
    metrics[metric] = stats[metric]
  end

  distributions = CSV.parse(File.read(locust_distribution_file))
  distributions = distributions.select do |dist|
    dist.include? "None Total"
  end

  # Only add distributions if we actually have any
  if distributions
    distributions = distributions.reverse.first
    ["100th_percentile", "99th_percentile", "98th_percentile", "95th_percentile", "90th_percentile",
     "80th_percentile", "75th_percentile", "66th_percentile", "50th_percentile"].each do |metric|
      metrics[metric] = distributions.pop if metrics.key?(metric)
    end
  end

  metric_service_client = Google::Cloud::Monitoring::Metric.new(version: :v3)
  formatted_name = Google::Cloud::Monitoring::V3::MetricServiceClient.project_path(@project_id)

  time_series = []
  time = Time.now.to_i

  metrics.each do |metric, value|

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

  metric_service_client.create_time_series(formatted_name, time_series)
end
