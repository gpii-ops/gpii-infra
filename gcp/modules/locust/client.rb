require "json"
require "google/cloud/monitoring"

@project_id = ENV['PROJECT_ID']

def process_locust_result(locust_result_file, app_name)
  locust_result = JSON.parse(File.read(locust_result_file))
  total_stats = locust_result["stats"].select do |stats|
    stats["name"] == "Total"
  end
  total_stats = total_stats.first

  metric_service_client = Google::Cloud::Monitoring::Metric.new(version: :v3)
  formatted_name = Google::Cloud::Monitoring::V3::MetricServiceClient.project_path(@project_id)
  time_series = []

  ["median_response_time", "min_response_time", "max_response_time",
   "avg_response_time", "num_failures", "num_requests"].each do |metric|

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
              "seconds" => Time.now.to_i,
              "nanos" => 0
            }
          },
          "value" => {
            "double_value" => total_stats[metric]
          }
        }
      ]
    }
  end

  puts "Posting Locust results for \"#{app_name}\" to Stackdriver..."
  metric_service_client.create_time_series(formatted_name, time_series)
end
