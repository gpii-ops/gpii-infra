from locust import HttpLocust, TaskSet, task
import random

class GpiiTasks(TaskSet):
  _keys = ['carla', 'vladimir', 'wayne', 'omar', 'telugu']
  @task
  def prefByKey(self):
      self.client.get("/preferences/" + random.choice(self._keys))


class GpiiWarmer(HttpLocust):
  task_set = GpiiTasks
  min_wait = 1000
  max_wait = 3000
