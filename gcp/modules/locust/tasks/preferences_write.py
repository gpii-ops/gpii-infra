from locust import HttpLocust, TaskSet, task, events
import random
import os
import json
import time

import on_failure
events.request_failure += on_failure

def generate_random_username():
    username_bases = ["rando", "chancey", "extra"]
    username_prefix = random.choice(username_bases)
    username_suffix = str(random.randrange(0,9999,1)).rjust(4,'0')
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

    # PUT a valid payload.
    random_username = generate_random_username()
    prefs_random_keyed_url = prefs_keyed_url_template.format(random_username)
    with l.client.put(prefs_random_keyed_url, name="1. PUT valid prefs with a GPII key.", json=prefs_in_context, verify=False, catch_response=True) as settings_put_response:
        print ("PUT response:" + json.dumps(settings_put_response.json()) + "...")
        if settings_put_response.status_code == 200:
            if json_deep_eq(prefs_in_context, settings_put_response.json()["preferences"]):
                settings_put_response.success()
            else:
                settings_put_response.failure("The PUT response should contain the original payload we submitted.")
        else:
            settings_put_response.failure("A valid prefs payload should have been PUT (error follows):\n" + settings_put_response.text)

    # TODO: Remove this once we can lock down the issues that result in a successful add before the record is persisted.
    time.sleep(l.hard_pause_seconds)

    # GET the data we just PUT and test it.
    with l.client.get(prefs_random_keyed_url, name="2. GET the prefs we just PUT.", verify=False, catch_response=True) as settings_get_response_after_put:
        print ("post-POST PUT response:" + json.dumps(settings_get_response_after_put.json()) + "...")
        if settings_get_response_after_put.status_code == 200:
            if json_deep_eq(prefs_in_context, settings_get_response_after_put.json()):
                settings_get_response_after_put.success()
            else:
                settings_get_response_after_put.failure("The data we GET should match the data we just PUT.")
        else:
            settings_get_response_after_put.failure("We should be able to GET the payload we just PUT (error follows):\n" + settings_get_response_after_put.text)

    # POST a valid payload
    new_gpii_key = "not-found-at-all"

    # We need to catch the results ourselves to pick up the system-generated gpiiKey.
    with l.client.post(prefs_unkeyed_url, name="3. POST valid prefs without a GPII key.", json=prefs_in_context, verify=False, catch_response=True) as valid_post_response:
        print ("POST response:" + json.dumps(valid_post_response.json()) + "...")
        if valid_post_response.status_code == 200:
            new_gpii_key = valid_post_response.json()["gpiiKey"]
            if json_deep_eq(prefs_in_context, valid_post_response.json()["preferences"]):
                valid_post_response.success()
            else:
                valid_post_response.failure("The POST response should contain the original payload we submitted, but was instead:" + valid_post_response.text)
        else:
            valid_post_response.failure("A valid prefs payload should have been POSTed (error follows):\n" + valid_post_response.text)


    # TODO: Remove this once we can lock down the issues that result in a successful add before the record is persisted.
    time.sleep(l.hard_pause_seconds)

    # GET the data we just POSTed and check it.
    new_key_url = prefs_keyed_url_template.format(new_gpii_key)
    with l.client.get(new_key_url, name="4. GET the prefs we just POSTed.", verify=False, catch_response=True) as settings_get_response_after_post:
        print ("post-POST GET response:" + json.dumps(settings_get_response_after_post.json()) + "...")
        if settings_get_response_after_post.status_code == 200:
            if json_deep_eq(prefs_in_context, settings_get_response_after_post.json()):
                settings_get_response_after_post.success()
            else:
                settings_get_response_after_post.failure("The data we GET should match the data we just PUT, but was instead:" + settings_get_response_after_post.text)
        else:
            settings_get_response_after_post.failure("We should be able to GET the payload we just PUT (error follows):\n" + settings_get_response_after_post.text)

    # TODO: Add a check for invalid POSTs once we support validation.

class PreferencesWriteTasks(TaskSet):
    # We need to pause between writing and reading material, see:
    hard_pause_seconds = .375
    @task
    def my_task(self):
        exercise_settings_endpoints(self)

class PreferencesWriteWarmer(HttpLocust):
    task_set = PreferencesWriteTasks
    min_wait = 5000
    max_wait = 9000
