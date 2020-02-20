from locust import HttpLocust, TaskSet, task, events
import random

from common import on_failure
events.request_failure += on_failure

class PreferencesReadTasks(TaskSet):

  def on_start(self):
    self.common = MorphicCommon()

  @task
  def get_pref_by_key(self):
      self.client.get(
        "/preferences/" + random.choice(self.common.default_docs),
        name = "/preferences/ID"
      )


class PreferencesReadWarmer(HttpLocust):
  task_set = PreferencesReadTasks
  min_wait = 1000
  max_wait = 3000
