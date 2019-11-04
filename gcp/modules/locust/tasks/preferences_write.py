from locust import HttpLocust, TaskSet, task, events
import random
import os
import json
import time
import string

import on_failure
events.request_failure += on_failure

def generate_random_username():
    username_bases = ["rando", "chancey", "extra"]
    username_prefix = random.choice(username_bases)
    username_suffix = "-"
    for x in range(0,10):
        username_suffix += random.choice(string.ascii_letters)

    return username_prefix + username_suffix

def json_deep_eq(expected, actual):
    expected_string = json.dumps(expected, sort_keys=True)
    actual_string = json.dumps(actual, sort_keys=True)
    if expected_string != actual_string:
        print ("Expected:\n" + expected_string);
        print ("Actual:\n" + actual_string);
    return expected_string == actual_string

def exercise_settings_endpoints(l):
    prefs_keyed_url_template = "/preferences/{}"
    prefs_unkeyed_url = "/preferences/"

    random_brightness = random.randrange(1,100,1)

    prefs_only = {
        "http://registry.gpii.net/common/screenBrightness": random_brightness
    }

    prefs_in_context = {
        "contexts": {
            "gpii-default": {
                "name": "Default preferences",
                "preferences": prefs_only
            }
        }
    }

    # TODO: Try to PUT an invalid payload once we have validation again.

    # PUT a valid payload
    random_username = generate_random_username()
    prefs_random_keyed_url = prefs_keyed_url_template.format(random_username)
    with l.client.put(prefs_random_keyed_url, name="1. PUT valid prefs with a GPII key.", json=prefs_in_context, verify=False, catch_response=True) as settings_put_response:
        if settings_put_response.status_code == 200 and not json_deep_eq(prefs_in_context, settings_put_response.json()["preferences"]):
            settings_put_response.failure("The PUT response should contain the original payload we submitted.")

    # TODO: Remove this once we can lock down the issues that result in a successful add before the record is persisted.
    time.sleep(l.hard_pause_seconds)

    # GET the data we just PUT
    with l.client.get(prefs_random_keyed_url, name="2. GET the prefs we just PUT.", verify=False, catch_response=True) as settings_get_response_after_put:
        if settings_get_response_after_put.status_code == 200 and not json_deep_eq(prefs_in_context, settings_get_response_after_put.json()):
            settings_get_response_after_put.failure("The data we GET should match the data we just PUT.")

    # POST a valid payload
    new_gpii_key = "not-found-at-all"

    with l.client.post(prefs_unkeyed_url, name="3. POST valid prefs without a GPII key.", json=prefs_in_context, verify=False, catch_response=True) as valid_post_response:
        if valid_post_response.status_code == 200 and not json_deep_eq(prefs_in_context, valid_post_response.json()["preferences"]):
            valid_post_response.failure("The POST response should contain the original payload we submitted.")

    # If we get this far, we should be able to extract the system-generated gpiiKey from the previous request.
    new_gpii_key = valid_post_response.json()["gpiiKey"]

    # TODO: Remove this once we can lock down the issues that result in a successful add before the record is persisted.
    time.sleep(l.hard_pause_seconds)

    # GET the data we just POSTed
    new_key_url = prefs_keyed_url_template.format(new_gpii_key)
    with l.client.get(new_key_url, name="4. GET the prefs we just POSTed.", verify=False, catch_response=True) as settings_get_response_after_post:
        if settings_get_response_after_post.status_code == 200 and not json_deep_eq(prefs_in_context, settings_get_response_after_post.json()):
            settings_get_response_after_post.failure("The data we GET should match the data we just PUT.")

    # TODO: Add a check for invalid POSTs once we support validation.

class PreferencesWriteTasks(TaskSet):
    # We need to pause between writing and reading material, see:
    hard_pause_seconds = .5
    @task
    def my_task(self):
        exercise_settings_endpoints(self)

class PreferencesWriteWarmer(HttpLocust):
    task_set = PreferencesWriteTasks
    min_wait = 5000
    max_wait = 9000
