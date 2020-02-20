from locust import HttpLocust, TaskSet, task, events
import random

from common import MorphicCommon, on_failure
events.request_failure += on_failure

class FlowmanagerTasks(TaskSet):

  def on_start(self):
    self.common = MorphicCommon()

  @task
  def post_access_token(self):
      self.client.post("/access_token", {
        "username": random.choice(self.common.default_docs),
        "password": "dummy",
        "client_id": "pilot-computer",
        "client_secret": "pilot-computer-secret",
        "grant_type": "password"
      })

class FlowmanagerWarmer(HttpLocust):
  task_set = FlowmanagerTasks
  min_wait = 1000
  max_wait = 3000
