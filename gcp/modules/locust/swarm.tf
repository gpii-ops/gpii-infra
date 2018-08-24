resource "null_resource" "locust_swarm_session" {
  depends_on = ["module.locust"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      RETRIES=10
      RETRY_COUNT=1
      while [ "$WORKERS_READY" != "${var.locust_workers}" ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Waiting for all Locust workers to join the master..."
        WORKERS_READY=$(kubectl -n locust logs deployment/locust-master --tail 1 | grep -oE "Currently \d+ clients" | grep -oE "\d+")
        if [ "$WORKERS_READY" == "" ]; then
          WORKERS_READY=0
        fi
        echo "Number of ready workers: $WORKERS_READY out of ${var.locust_workers}!"
        RETRY_COUNT=$(($RETRY_COUNT+1))
        if [ "$RETRY_COUNT" -ge "$RETRIES" ] ; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        sleep 10
      done

      LOCUST_URL=http://127.0.0.1:8089
      kubectl -n locust port-forward deployment/locust-master 8089:8089 </dev/null &>/dev/null &
      sleep 5

      echo
      echo "Starting Locust swarm with ${var.locust_users} users and hatch rate of ${var.locust_hatch_rate}!"
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
      total_rps=$(echo $SESSION_STATS | jq -r ".total_rps | floor")
      median_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").median_response_time | floor')
      max_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").max_response_time | floor')
      num_failures=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").num_failures')

      echo
      echo $SESSION_STATS
      EXIT_STATUS=0

      if [ $total_rps -lt ${var.locust_desired_total_rps} ]; then
        echo
        echo "Looks like total_rps ($total_rps) is worse than desired (${var.locust_desired_total_rps})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ $median_response_time -gt ${var.locust_desired_median_response_time} ]; then
        echo
        echo "Looks like median_response_time ($median_response_time) is worse than desired (${var.locust_desired_median_response_time})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ $max_response_time -gt ${var.locust_desired_max_response_time} ]; then
        echo
        echo "Looks like max_response_time ($max_response_time) is worse than desired (${var.locust_desired_max_response_time})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ $num_failures -gt ${var.locust_desired_num_failures} ]; then
        echo
        echo "Looks like num_failures ($num_failures) is worse than desired (${var.locust_desired_num_failures})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      echo
      echo "Stats distribution:"
      curl -s $LOCUST_URL/stats/distribution/csv

      echo
      echo "Resetting stats..."
      curl -s $LOCUST_URL/stats/reset
      kill $(pgrep -f "^kubectl -n locust port-forward")
      exit $EXIT_STATUS
    EOF
  }
}
