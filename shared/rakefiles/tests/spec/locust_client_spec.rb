require "../../../gcp/modules/locust/client.rb"

describe LocustClient do
  all_stats = {
    "current_response_time_percentile_50" => 35.44497489929199,
    "current_response_time_percentile_95" => 130,
    "errors" => [],
    "fail_ratio" => 0.0,
    "slaves" => [
      {
        "id" => "locust-worker-5f496b799c-tfqkz_9fbd43f49de6bcd21f8781d8dea88722",
        "state" => "ready",
        "user_count" => 0
      },
      {
        "id" => "locust-worker-5f496b799c-7wdv8_245bc7f5ad9b1cc53d7d41ed189a77c9",
        "state" => "ready",
        "user_count" => 0
      },
      {
        "id" => "locust-worker-5f496b799c-f5gtn_8f4606138d2d77dac9314f84cb420642",
        "state" => "ready",
        "user_count" => 0
      }
    ],
    "state" => "stopped",
    "stats" => [
      {
        "avg_content_length" => 1549.0,
        "avg_response_time" => 51.929161415337035,
        "current_rps" => 5.1,
        "max_response_time" => 206.20465278625488,
        "median_response_time" => 35.3388786315918,
        "method" => "GET",
        "min_response_time" => 24.288654327392578,
        "name" => "/preferences/carla",
        "num_failures" => 0,
        "num_requests" => 161
      },
      {
        "avg_content_length" => 230.0,
        "avg_response_time" => 54.46851326644055,
        "current_rps" => 4.9,
        "max_response_time" => 246.76275253295898,
        "median_response_time" => 34.682512283325195,
        "method" => "GET",
        "min_response_time" => 25.01654624938965,
        "name" => "/preferences/omar",
        "num_failures" => 0,
        "num_requests" => 163
      },
      {
        "avg_content_length" => 127.0,
        "avg_response_time" => 58.07704325543334,
        "current_rps" => 4.1,
        "max_response_time" => 304.4097423553467,
        "median_response_time" => 35.29095649719238,
        "method" => "GET",
        "min_response_time" => 26.116371154785156,
        "name" => "/preferences/telugu",
        "num_failures" => 0,
        "num_requests" => 151
      },
      {
        "avg_content_length" => 1811.0,
        "avg_response_time" => 61.312959997693476,
        "current_rps" => 4.9,
        "max_response_time" => 220.21007537841797,
        "median_response_time" => 39.60132598876953,
        "method" => "GET",
        "min_response_time" => 25.2230167388916,
        "name" => "/preferences/vladimir",
        "num_failures" => 0,
        "num_requests" => 181
      },
      {
        "avg_content_length" => 157.0,
        "avg_response_time" => 57.68972496653712,
        "current_rps" => 5.3,
        "max_response_time" => 247.99251556396484,
        "median_response_time" => 35.169124603271484,
        "method" => "GET",
        "min_response_time" => 24.60002899169922,
        "name" => "/preferences/wayne",
        "num_failures" => 0,
        "num_requests" => 172
      },
      {
        "avg_content_length" => 798.1292270531401,
        "avg_response_time" => 56.798157772580204,
        "current_rps" => 24.3,
        "max_response_time" => 304.4097423553467,
        "median_response_time" => 35.97688674926758,
        "method" => nil,
        "min_response_time" => 24.288654327392578,
        "name" => "Total",
        "num_failures" => 0,
        "num_requests" => 828
      }
    ],
    "total_rps" => 24.3,
    "user_count" => 0
  }

  all_distributions_csv = <<eof
"Name","# requests","50%","66%","75%","80%","90%","95%","98%","99%","100%"
"GET /preferences/carla",161,35,44,62,73,100,120,170,190,210
"GET /preferences/omar",163,34,47,65,82,110,130,150,200,250
"GET /preferences/telugu",151,35,59,81,92,120,140,150,180,300
"GET /preferences/vladimir",181,39,70,90,98,110,140,160,180,220
"GET /preferences/wayne",172,35,52,73,92,120,150,190,210,250
"Total",828,36,54,74,90,110,140,170,190,300
eof
  all_distributions = CSV.parse(all_distributions_csv)
  it "collect_metrics runs" do
    LocustClient.collect_metrics(all_stats, all_distributions)
  end
end


# vim: set et ts=2 sw=2:
