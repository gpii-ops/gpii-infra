from locust import HttpLocust, TaskSet, task
import random

class PreferencesTasks(TaskSet):

  _keys = ["carla", "vladimir", "wayne", "omar", "telugu"]

  @task
  def getPrefByKey(self):
      self.client.get("/preferences/" + random.choice(self._keys))


class PreferencesWarmer(HttpLocust):
  task_set = PreferencesTasks
  min_wait = 1000
  max_wait = 3000
