from locust import HttpLocust, TaskSet, task, events
import random
import os

import on_failure
events.request_failure += on_failure

def generate_random_username():
    username_bases = ["rando", "chancey", "extra"]
    username_prefix = random.choice(username_bases)
    username_suffix = str(random.randrange(0,9999,1)).rjust(4,'0')
    return username_prefix + username_suffix

def exercise_settings_endpoints(l):
    prefs_keyed_url_template = "/preferences/{}"
    prefs_unkeyed_url = "/preferences/"

    random_brightness = random.randrange(1,100,1)
    prefs_payload = {
        "contexts": {
            "gpii-default": {
                "name": "Default preferences",
                "preferences": {
                    "http://registry.gpii.net/common/screenBrightness": random_brightness
                }
            }
        }
    }

    # PUT a valid payload.
    random_username = generate_random_username()
    prefs_random_keyed_url = prefs_keyed_url_template.format(random_username)
    settings_put_response = l.client.put(prefs_random_keyed_url, name="1. PUT valid prefs with a GPII key.", data=prefs_payload, verify=False)

    # TODO: Try to PUT an invalid payload once we have validation again.

    # GET the data we just PUT up.
    settings_get_response = l.client.get(prefs_random_keyed_url, name="2. GET the prefs we just PUT.", verify=False)

    # POST a valid payload
    new_gpii_key = "not-found-at-all"
    # We need to catch the results ourselves to pick up the system-generated gpiiKey.
    with l.client.post(prefs_unkeyed_url, name="3. POST valid prefs without a GPII key.", data=prefs_payload, verify=False, catch_response=True) as valid_post_response:
        if valid_post_response.status_code == 200:
            new_gpii_key = valid_post_response.json()["gpiiKey"]
            valid_post_response.success()
        else:
            valid_post_response.failure("A valid prefs payload should have been POSTed (error follows):\n" + valid_post_response.text)


    # GET the data we just POSTed and check it.
    new_key_url = prefs_keyed_url_template.format(new_gpii_key)
    settings_get_response = l.client.get(new_key_url, name="4. GET the prefs we just POSTed.", verify=False)

    # TODO: Add a check for invalid POSTs once we support validation.

class PreferencesWriteTasks(TaskSet):
    @task
    def my_task(self):
        exercise_settings_endpoints(self)

class PreferencesWriteWarmer(HttpLocust):
    task_set = PreferencesWriteTasks
    min_wait = 5000
    max_wait = 9000
