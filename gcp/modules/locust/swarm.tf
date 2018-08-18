resource "null_resource" "locust_swarm_session" {
  depends_on = ["module.locust"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      if [ "${var.locust_swarm}" == "" ]; then
        echo "Looks like TF_VAR_locust_swarm is unset, terminating!"
        exit
      fi
      LOCUST_URL=http://127.0.0.1:8089
      kubectl --namespace locust port-forward deployment/locust-master 8089:8089 </dev/null &>/dev/null &
      sleep 5

      echo
      echo "Starting Locust swarm with ${var.locust_users} users and ${var.locust_hatch_rate} hatch rate!"
      curl -s -XPOST $LOCUST_URL/swarm -d"locust_count=${var.locust_users}&hatch_rate=${var.locust_hatch_rate}"

      echo
      echo "USERS  RPS     STATUS"
      SWARM_DURATION=${var.locust_swarm_duration}
      while [ "$SWARM_DURATION" != "0" ]; do
        curl -s $LOCUST_URL/stats/requests | jq -r '[.user_count, (.total_rps | floor), .state] | @tsv'
        SWARM_DURATION=$(($SWARM_DURATION-1))
        sleep 1
      done

      echo
      echo "Swarming complete!"
      curl -s $LOCUST_URL/stop

      echo
      echo "Processing stats..."
      SESSION_STATS=$(curl -s $LOCUST_URL/stats/requests)
      median_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").median_response_time | floor')
      max_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").max_response_time | floor')
      num_failures=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").num_failures')

      echo
      echo $SESSION_STATS
      SESSION_SUCCEEDED=1

      if [ $median_response_time -gt ${var.locust_desired_median_response_time} ]; then
        echo
        echo "Looks like median_response_time($median_response_time) is worse than desired(${var.locust_desired_median_response_time})!"
        echo "This is unacceptable!"
        SESSION_SUCCEEDED=0
      fi

      if [ $max_response_time -gt ${var.locust_desired_max_response_time} ]; then
        echo
        echo "Looks like max_response_time($max_response_time) is worse than desired(${var.locust_desired_max_response_time})!"
        echo "This is unacceptable!"
        SESSION_SUCCEEDED=0
      fi

      if [ $num_failures -gt ${var.locust_desired_num_failures} ]; then
        echo
        echo "Looks like num_failures($num_failures) is worse than desired(${var.locust_desired_num_failures})!"
        echo "This is unacceptable!"
        SESSION_SUCCEEDED=0
      fi

      echo
      echo "Stats distribution:"
      curl -s $LOCUST_URL/stats/distribution/csv

      echo
      echo "Resetting stats..."
      curl -s $LOCUST_URL/stats/reset
      kill $(pgrep kubectl)

      if [ "$SESSION_SUCCEEDED" != "1" ]; then
        exit 1
      fi
    EOF
  }
}
