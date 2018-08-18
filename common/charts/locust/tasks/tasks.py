from locust import HttpLocust, TaskSet, task

class GpiiTasks(TaskSet):
  @task
  def carla(self):
      self.client.get("/preferences/carla")

  @task
  def vladimir(self):
      self.client.get("/preferences/vladimir")

class GpiiWarmer(HttpLocust):
  task_set = GpiiTasks
  min_wait = 1000
  max_wait = 3000
