import json, random

from locust import HttpLocust, TaskSet, task, events
from common import MorphicCommon, on_failure

events.request_failure += on_failure

class CouchReadTasks(TaskSet):

    def on_start(self):
      self.common = MorphicCommon()

    @task(10)
    def get_doc_by_key(self):
      self.client.get(
        "/" + self.common.db_name + "/" + random.choice(self.common.default_docs),
        name = "/" + self.common.db_name + "/ID",
        auth = (self.common.basic_auth_user, self.common.basic_auth_password)
      )

    @task(5)
    def get_doc_with_rev_info_by_key(self):
      self.client.get(
        "/" + self.common.db_name + "/" + random.choice(self.common.default_docs) + "?revs_info=true",
        name = "/" + self.common.db_name + "/ID?revs_info=true",
        auth = (self.common.basic_auth_user, self.common.basic_auth_password)
      )

class CouchWarmer(HttpLocust):
  task_set = CouchReadTasks
  min_wait = 10
  max_wait = 50
