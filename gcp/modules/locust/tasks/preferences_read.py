from locust import HttpLocust, TaskSet, task, events
import random

import on_failure
events.request_failure += on_failure

class PreferencesReadTasks(TaskSet):

  _keys = ["carla", "vladimir", "wayne", "omar", "nvda"]

  @task
  def get_pref_by_key(self):
      self.client.get("/preferences/" + random.choice(self._keys))


class PreferencesReadWarmer(HttpLocust):
  task_set = PreferencesReadTasks
  min_wait = 1000
  max_wait = 3000
