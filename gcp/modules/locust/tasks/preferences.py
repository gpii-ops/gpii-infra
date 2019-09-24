from locust import HttpLocust, TaskSet, task, events
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
