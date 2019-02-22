resource "null_resource" "locust_swarm_session" {
  depends_on = ["module.locust"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      if [ "${var.locust_swarm_duration}" == "" ] ||
         [ "${var.locust_target_app}" == "" ] ||
         [ "${var.locust_target_host}" == "" ] ||
         [ "${var.locust_script}" == "" ]; then
        echo
        echo
        echo "Looks like some mandatory Locust vars are unset, terminating!"
        echo "Mandatory vars are:"
        echo "  TF_VAR_locust_swarm_duration"
        echo "  TF_VAR_locust_target_app"
        echo "  TF_VAR_locust_target_host"
        echo "  TF_VAR_locust_script"
        echo
        exit 1
      fi

      RETRIES=20
      RETRY_COUNT=1
      WORKERS_READY=0
      while [ "$WORKERS_READY" -lt "${var.locust_workers}" ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Waiting for all Locust workers to join the master..."
        WORKERS_READY=$(kubectl -n locust logs deployment/locust-master --tail 1 | grep -oE "Currently \d+ clients" | grep -oE "\d+")
        if [ "$WORKERS_READY" == "" ]; then
          WORKERS_READY=0
        fi
        echo "Number of ready workers: $WORKERS_READY out of ${var.locust_workers}!"
        if [ "$RETRY_COUNT" == "$RETRIES" ]; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        sleep 10
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done

      LOCUST_URL="http://127.0.0.1:8089"
      PORT_FORWARD_CMD="kubectl -n locust port-forward deployment/locust-master 8089:8089"

      $PORT_FORWARD_CMD </dev/null &>/dev/null &
      sleep 5

      echo
      echo "Starting Locust swarm with ${var.locust_users} users and hatch rate of ${var.locust_hatch_rate}!"
      curl -s -XPOST $LOCUST_URL/swarm -d"locust_count=${var.locust_users}&hatch_rate=${var.locust_hatch_rate}"

      echo
      echo "USERS  RPS     STATUS"
      SWARM_DURATION="${var.locust_swarm_duration}"
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
      median_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").median_response_time | . // 0 | floor')
      max_response_time=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").max_response_time | floor')
      num_failures=$(echo $SESSION_STATS | jq -r '.stats[] | select(.name == "Total").num_failures')

      echo
      echo "$SESSION_STATS"
      echo "$SESSION_STATS" > ${path.cwd}/${var.locust_target_app}.stats

      echo
      echo "Stats distribution:"
      SESSION_STATS_DISTRIBUTION=$(curl -s $LOCUST_URL/stats/distribution/csv)
      echo "$SESSION_STATS_DISTRIBUTION"
      echo "$SESSION_STATS_DISTRIBUTION" > ${path.cwd}/${var.locust_target_app}.distribution

      echo
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}

      EXIT_STATUS=1
      RETRIES=5
      RETRY_COUNT=1
      while [ "$RETRY_COUNT" -le "$RETRIES" -a "$EXIT_STATUS" != "0"  ]; do
        echo "[Try $RETRY_COUNT of $RETRIES] Posting Locust results for \"${var.locust_target_app}\" to Stackdriver..."
        ruby -e '
          require "${path.module}/client.rb"
          LocustClient.process_locust_result("${path.cwd}/${var.locust_target_app}.stats", "${path.cwd}/${var.locust_target_app}.distribution", "${var.locust_target_app}", "${var.locust_users}")
        '
        EXIT_STATUS="$?"

        # Sleep only if this is not the last run
        if [ "$RETRY_COUNT" -lt "$RETRIES" -a "$EXIT_STATUS" != "0" ]; then
          sleep 10
        fi
        RETRY_COUNT=$((RETRY_COUNT+1))
      done
      [ "$EXIT_STATUS" != "0" ] && echo "Failed to post resutls to Stackdriver, retry limit reached, giving up."

      if [ "$total_rps" -lt "${var.locust_desired_total_rps}" ]; then
        echo
        echo "Looks like total_rps ($total_rps) is worse than desired (${var.locust_desired_total_rps})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ "$median_response_time" -gt "${var.locust_desired_median_response_time}" ]; then
        echo
        echo "Looks like median_response_time ($median_response_time) is worse than desired (${var.locust_desired_median_response_time})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ "$max_response_time" -gt "${var.locust_desired_max_response_time}" ]; then
        echo
        echo "Looks like max_response_time ($max_response_time) is worse than desired (${var.locust_desired_max_response_time})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      if [ "$num_failures" -gt "${var.locust_desired_num_failures}" ]; then
        echo
        echo "Looks like num_failures ($num_failures) is worse than desired (${var.locust_desired_num_failures})!"
        echo "This is unacceptable!"
        EXIT_STATUS=1
      fi

      echo
      echo "Resetting stats..."
      curl -s $LOCUST_URL/stats/reset
      kill $(pgrep -f "^$PORT_FORWARD_CMD")
      exit $EXIT_STATUS
    EOF
  }
}
