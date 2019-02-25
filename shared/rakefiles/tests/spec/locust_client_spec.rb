require "../../../gcp/modules/locust/client.rb"

describe LocustClient do
  fake_stats = {
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

  fake_distributions_csv = <<eof
"Name","# requests","50%","66%","75%","80%","90%","95%","98%","99%","100%"
"GET /preferences/carla",161,35,44,62,73,100,120,170,190,210
"GET /preferences/omar",163,34,47,65,82,110,130,150,200,250
"GET /preferences/telugu",151,35,59,81,92,120,140,150,180,300
"GET /preferences/vladimir",181,39,70,90,98,110,140,160,180,220
"GET /preferences/wayne",172,35,52,73,92,120,150,190,210,250
"Total",828,36,54,74,90,110,140,170,190,300
eof
  fake_distributions = CSV.parse(fake_distributions_csv)

  fake_user_count = 11111

  it "collect_metrics collects metrics from fake_stats and fake_distributions" do
    actual_metrics = LocustClient.collect_metrics(fake_stats, fake_distributions, fake_user_count)
    # A metric from fake_stats
    expect(actual_metrics).to include("num_requests" => 828)
    # A metric from fake_distributions
    expect(actual_metrics).to include("100th_percentile" => "300")
  end

  it "collect_metrics does not explode when fake_distributions is empty" do
    empty_distributions_csv = <<eof
"Name","# requests","50%","66%","75%","80%","90%","95%","98%","99%","100%"
eof
    empty_distributions = CSV.parse(empty_distributions_csv)
    actual_metrics = LocustClient.collect_metrics(fake_stats, empty_distributions, fake_user_count)
    # A metric from fake_stats
    expect(actual_metrics).to include("num_requests" => 828)
    # A metric from fake_distributions
    expect(actual_metrics.keys).not_to include("100th_percentile")
  end

  it "collect_metrics does not explode when fake_stats has only failures" do
    fail_stats = {
      "current_response_time_percentile_50" => nil,
      "current_response_time_percentile_95" => nil,
      "errors" => [
        {
          "error" => "'SSLError(MaxRetryError(\"HTTPSConnectionPool(host=\\'preferences.stepan.dev.gcp.gpii.net\\', port=443): Max retries exceeded with url: /preferences/carla (Caused by SSLError(SSLError(1, \\'[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:841)\\'),))\",),)'",
          "method" => "GET",
          "name" => "/preferences/carla",
          "occurences" => 133
        },
        {
          "error" => "'SSLError(MaxRetryError(\"HTTPSConnectionPool(host=\\'preferences.stepan.dev.gcp.gpii.net\\', port=443): Max retries exceeded with url: /preferences/omar (Caused by SSLError(SSLError(1, \\'[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:841)\\'),))\",),)'",
          "method" => "GET",
          "name" => "/preferences/omar",
          "occurences" => 146
        },
        {
          "error" => "'SSLError(MaxRetryError(\"HTTPSConnectionPool(host=\\'preferences.stepan.dev.gcp.gpii.net\\', port=443): Max retries exceeded with url: /preferences/vladimir (Caused by SSLError(SSLError(1, \\'[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:841)\\'),))\",),)'",
          "method" => "GET",
          "name" => "/preferences/vladimir",
          "occurences" => 121
        },
        {
          "error" => "'SSLError(MaxRetryError(\"HTTPSConnectionPool(host=\\'preferences.stepan.dev.gcp.gpii.net\\', port=443): Max retries exceeded with url: /preferences/telugu (Caused by SSLError(SSLError(1, \\'[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:841)\\'),))\",),)'",
          "method" => "GET",
          "name" => "/preferences/telugu",
          "occurences" => 142
        },
        {
          "error" => "'SSLError(MaxRetryError(\"HTTPSConnectionPool(host=\\'preferences.stepan.dev.gcp.gpii.net\\', port=443): Max retries exceeded with url: /preferences/wayne (Caused by SSLError(SSLError(1, \\'[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:841)\\'),))\",),)'",
          "method" => "GET",
          "name" => "/preferences/wayne",
          "occurences" => 121
        }
      ],
      "fail_ratio" => 1.0,
      "slaves" => [
        {
          "id" => "locust-worker-85f6779589-4hnzm_5414a9ea54f6cc2e4dfbe842b75778d0",
          "state" => "running",
          "user_count" => 17
        },
        {
          "id" => "locust-worker-85f6779589-s5jsk_24896bab2927be6afe06b1e793ec8a76",
          "state" => "ready",
          "user_count" => 0
        },
        {
          "id" => "locust-worker-85f6779589-gzs4x_d123fe4e78ba77cc08a76f83c1718cf0",
          "state" => "ready",
          "user_count" => 0
        }
      ],
      "state" => "running",
      "stats" => [
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => "GET",
          "min_response_time" => 0,
          "name" => "/preferences/carla",
          "num_failures" => 133,
          "num_requests" => 0
        },
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => "GET",
          "min_response_time" => 0,
          "name" => "/preferences/omar",
          "num_failures" => 146,
          "num_requests" => 0
        },
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => "GET",
          "min_response_time" => 0,
          "name" => "/preferences/telugu",
          "num_failures" => 142,
          "num_requests" => 0
        },
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => "GET",
          "min_response_time" => 0,
          "name" => "/preferences/vladimir",
          "num_failures" => 121,
          "num_requests" => 0
        },
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => "GET",
          "min_response_time" => 0,
          "name" => "/preferences/wayne",
          "num_failures" => 121,
          "num_requests" => 0
        },
        {
          "avg_content_length" => 0,
          "avg_response_time" => 0,
          "current_rps" => 0.0,
          "max_response_time" => 0,
          "median_response_time" => 0,
          "method" => nil,
          "min_response_time" => 0,
          "name" => "Total",
          "num_failures" => 663,
          "num_requests" => 0
        }
      ],
      "total_rps" => 0.0,
      "user_count" => 17
    }
    actual_metrics = LocustClient.collect_metrics(fail_stats, fake_distributions, fake_user_count)
    # If this doesn't raise an exception, we're ok.
  end

  it "collect_metrics uses user_count" do
    actual_metrics = LocustClient.collect_metrics(fake_stats, fake_distributions, fake_user_count)
    expect(actual_metrics).to include("user_count" => fake_user_count)
  end
end


# vim: set et ts=2 sw=2:
