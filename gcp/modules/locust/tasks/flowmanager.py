from locust import HttpLocust, TaskSet, task, events
import random

import on_failure
events.request_failure += on_failure

class FlowmanagerTasks(TaskSet):

  _keys = ["carla", "vladimir", "wayne", "omar", "nvda"]

  @task
  def post_access_token(self):
      self.client.post("/access_token", {
        "username": random.choice(self._keys),
        "password": "dummy",
        "client_id": "pilot-computer",
        "client_secret": "pilot-computer-secret",
        "grant_type": "password"
      })


class FlowmanagerWarmer(HttpLocust):
  task_set = FlowmanagerTasks
  min_wait = 1000
  max_wait = 3000
