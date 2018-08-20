from locust import HttpLocust, TaskSet, task

class GpiiTasks(TaskSet):
  @task
  def carla(self):
      self.client.get("/preferences/carla")

  @task
  def vladimir(self):
      self.client.get("/preferences/vladimir")

  @task
  def wayne(self):
      self.client.get("/preferences/wayne")

  @task
  def omar(self):
      self.client.get("/preferences/omar")

  @task
  def telugu(self):
      self.client.get("/preferences/telugu")

class GpiiWarmer(HttpLocust):
  task_set = GpiiTasks
  min_wait = 1000
  max_wait = 3000
