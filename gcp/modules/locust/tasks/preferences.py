from locust import HttpLocust, TaskSet, task
import random

class PreferencesTasks(TaskSet):

  _keys = ["carla", "vladimir", "wayne", "omar", "nvda"]

  @task
  def get_pref_by_key(self):
      self.client.get("/preferences/" + random.choice(self._keys))


class PreferencesWarmer(HttpLocust):
  task_set = PreferencesTasks
  min_wait = 1000
  max_wait = 3000
