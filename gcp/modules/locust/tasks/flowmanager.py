from locust import HttpLocust, TaskSet, task, events
import random

class FlowmanagerTasks(TaskSet):

  _keys = ["carla", "vladimir", "wayne", "omar", "nvda"]

  @task
  def post_access_token(self):
      self.client.post("/access_token", {
        "username": random.choice(self._keys),
        "password": "dummy",
        "client_id": "pilot-computer",
        "client_secret": "pilot-computer-secret",
        "grant_type": "password"
      })


class FlowmanagerWarmer(HttpLocust):
  task_set = FlowmanagerTasks
  min_wait = 1000
  max_wait = 3000


def on_failure(request_type, name, response_time, exception, **kwargs):
    print("Request: %s %s" % (request_type, name))
    if exception.request is not None:
        print("URL: %s" % (exception.request.url))
    print("Exception: %s" % (exception))
    if exception.response is not None:
        print("Code: %s" % (exception.response.status_code))
        print("Headers: %s" % (exception.response.headers))
        print("Content: %s" % (exception.response.content))

events.request_failure += on_failure
