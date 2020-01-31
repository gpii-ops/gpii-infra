import json, random

from locust import HttpLocust, TaskSequence, seq_task, events
from common import MorphicCommon, on_failure

events.request_failure += on_failure

class MorphicWriteTasks(TaskSequence):

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
    def put_settings(self):
      payload = random.choice(self.common.settings_puts)
      self.client.put(
          "/" + self.common.username + "/settings",
          name = "/settings",
          headers = {
            "Authorization": "Bearer " + self.access_token,
            "Content-Type": "application/json",
          },
          json = payload
      )


class FlowmanagerWarmer(HttpLocust):
  task_set = MorphicWriteTasks
  min_wait = 500
  max_wait = 1000
