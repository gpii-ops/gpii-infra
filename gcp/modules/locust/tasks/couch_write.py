import json, random, uuid

from locust import HttpLocust, TaskSet, task, events
from common import MorphicCommon, on_failure

events.request_failure += on_failure

class CouchWriteTasks(TaskSet):

    def on_start(self):
      self.common = MorphicCommon()

    @task
    def post_doc(self):
      data = random.choice(self.common.sample_docs)
      data["_id"] = str(uuid.uuid4())
      self.client.post(
        "/" + self.common.db_name,
        json = data,
        headers = { "Content-Type": "application/json" }
      )

class CouchWarmer(HttpLocust):
  task_set = CouchWriteTasks
  min_wait = 10
  max_wait = 50
