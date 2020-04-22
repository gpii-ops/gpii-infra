import json, random

from locust import HttpLocust, TaskSequence, seq_task, events
from common import MorphicCommon, on_failure

events.request_failure += on_failure

class MorphicReadTasks(TaskSequence):

    def on_start(self):
      self.common = MorphicCommon()

    @seq_task(1)
    def post_access_token(self):
      response = self.client.post(
        "/access_token",
        {
          "grant_type": "password",
          "password": "dummy",
          "client_id": self.common.client_id,
          "client_secret": self.common.client_secret,
          "username": self.common.username
        }
      )
      self.access_token = json.loads(response.text)['access_token']

    @seq_task(2)
    def get_settings(self):
      self.client.get(
          "/" + self.common.username + "/settings/" + random.choice(self.common.settings_gets),
          name = "/settings",
          headers = {"Authorization": "Bearer " + self.access_token}
      )


class FlowmanagerWarmer(HttpLocust):
  task_set = MorphicReadTasks
  min_wait = 500
  max_wait = 1000
