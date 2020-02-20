import os
from random import randint

class MorphicCommon:

    db_name = "gpii"

    default_docs = [
      "alice", "alsa", "andrei", "audio", "ben", "carla", "catalina", "chris", "chromeDefault", "clientCredential-1", "condTest", "condTest2", "davey", "david", "debbie", "easit1", "easit2", "elaine", "elmer", "elmerv", "elod", "empty", "explodeLaunchHandlerStart", "explodeLaunchHandlerStop", "explodeSettingsHandlerGet", "explodeSettingsHandlerSet", "franklin", "gert", "gpiiAppInstallationClient-1", "intra_application", "jaws", "jme_app", "jme_common", "li", "liam", "livia", "lorie", "maggie", "magic", "maguro", "manuel", "mary", "mickey", "mobileaccessibility1", "mobileaccessibility2", "multi_context", "naomi", "nisha", "nvda", "nyx", "olb_Alicia_app", "olga", "oliver", "omar", "omnitor1", "omnitor2", "os_android", "os_android_common", "otis", "phil", "prefsSafe-GPII-270-rbmm-demo", "prefsSafe-MikelVargas", "prefsSafe-alice", "prefsSafe-alsa", "prefsSafe-andrei", "prefsSafe-audio", "prefsSafe-ben", "prefsSafe-carla", "prefsSafe-catalina", "prefsSafe-chris", "prefsSafe-chromeDefault", "prefsSafe-condTest", "prefsSafe-condTest2", "prefsSafe-davey", "prefsSafe-david", "prefsSafe-debbie", "prefsSafe-easit1", "prefsSafe-easit2", "prefsSafe-elaine", "prefsSafe-elmer", "prefsSafe-elmerv", "prefsSafe-elod", "prefsSafe-empty", "prefsSafe-explodeLaunchHandlerStart", "prefsSafe-explodeLaunchHandlerStop", "prefsSafe-explodeSettingsHandlerGet", "prefsSafe-explodeSettingsHandlerSet", "prefsSafe-franklin", "prefsSafe-gert", "prefsSafe-intra_application", "prefsSafe-jaws", "prefsSafe-jme_app", "prefsSafe-jme_common", "prefsSafe-li", "prefsSafe-liam", "prefsSafe-livia", "prefsSafe-lorie", "prefsSafe-maggie", "prefsSafe-magic", "prefsSafe-maguro", "prefsSafe-manuel", "prefsSafe-mary", "prefsSafe-mickey", "prefsSafe-mobileaccessibility1", "prefsSafe-mobileaccessibility2", "prefsSafe-multi_context", "prefsSafe-naomi", "prefsSafe-nisha", "prefsSafe-nvda", "prefsSafe-nyx", "prefsSafe-olb_Alicia_app", "prefsSafe-olga", "prefsSafe-oliver", "prefsSafe-omar", "prefsSafe-omnitor1", "prefsSafe-omnitor2", "prefsSafe-os_android", "prefsSafe-os_android_common", "prefsSafe-otis", "prefsSafe-phil", "prefsSafe-rachel", "prefsSafe-randy", "prefsSafe-rebecca", "prefsSafe-review3_chrome_high_contrast", "prefsSafe-review3_ma1", "prefsSafe-review3_ma2", "prefsSafe-review3_user_1", "prefsSafe-review3_user_2", "prefsSafe-review3_user_3", "prefsSafe-review3_user_4", "prefsSafe-roger", "prefsSafe-rose", "prefsSafe-ryan", "prefsSafe-salem", "prefsSafe-sally", "prefsSafe-sammy", "prefsSafe-simon", "prefsSafe-slater", "prefsSafe-snapset_1a", "prefsSafe-snapset_1b", "prefsSafe-snapset_1c", "prefsSafe-snapset_2a", "prefsSafe-snapset_2b", "prefsSafe-snapset_2c", "prefsSafe-snapset_3", "prefsSafe-snapset_4a", "prefsSafe-snapset_4b", "prefsSafe-snapset_4c", "prefsSafe-snapset_4d", "prefsSafe-snapset_5", "prefsSafe-talkback1", "prefsSafe-talkback2", "prefsSafe-testUser1", "prefsSafe-timothy", "prefsSafe-tom", "prefsSafe-tony", "prefsSafe-tvm_jasmin", "prefsSafe-tvm_sammy", "prefsSafe-tvm_vladimir", "prefsSafe-uioPlusCommon", "prefsSafe-uioPlus_captions", "prefsSafe-uioPlus_character_space", "prefsSafe-uioPlus_defaults", "prefsSafe-uioPlus_font_size", "prefsSafe-uioPlus_high_contrast", "prefsSafe-uioPlus_highlight_colour", "prefsSafe-uioPlus_inputs_larger", "prefsSafe-uioPlus_line_space", "prefsSafe-uioPlus_multiple_settings", "prefsSafe-uioPlus_self_voicing", "prefsSafe-uioPlus_simplified", "prefsSafe-uioPlus_syllabification", "prefsSafe-uioPlus_toc", "prefsSafe-uioPlus_word_space", "prefsSafe-vicky", "prefsSafe-vladimir", "prefsSafe-wayne", "rachel", "randy", "rebecca", "review3_chrome_high_contrast", "review3_ma1", "review3_ma2", "review3_user_1", "review3_user_2", "review3_user_3", "review3_user_4", "roger", "rose", "ryan", "salem", "sally", "sammy", "simon", "slater", "snapset_1a", "snapset_1b", "snapset_1c", "snapset_2a", "snapset_2b", "snapset_2c", "snapset_3", "snapset_4a", "snapset_4b", "snapset_4c", "snapset_4d", "snapset_5", "talkback1", "talkback2", "testUser1", "timothy", "tom", "tony", "tvm_jasmin", "tvm_sammy", "tvm_vladimir", "uioPlusCommon", "uioPlus_captions", "uioPlus_character_space", "uioPlus_defaults", "uioPlus_font_size", "uioPlus_high_contrast", "uioPlus_highlight_colour", "uioPlus_inputs_larger", "uioPlus_line_space", "uioPlus_multiple_settings", "uioPlus_self_voicing", "uioPlus_simplified", "uioPlus_syllabification", "uioPlus_toc", "uioPlus_word_space", "vicky", "vladimir", "wayne"
    ]

    sample_docs = [
      {
        "type": "gpiiKey",
        "schemaVersion": "0.2",
        "prefsSafeId": "prefsSafe-carla",
        "prefsSetId": "gpii-default",
        "revoked": False,
        "revokedReason": None,
        "timestampCreated": None,
        "timestampUpdated": None
      },
      {
        "type": "clientCredential",
        "schemaVersion": "0.2",
        "clientId": "locust",
        "allowedIPBlocks": None,
        "allowedPrefsToWrite": None,
        "isCreateGpiiKeyAllowed": True,
        "isCreatePrefsSafeAllowed": True,
        "revoked": False,
        "revokedReason": None,
        "timestampCreated": None,
        "timestampRevoked": None
      },
      {
        "type": "gpiiAppInstallationClient",
        "schemaVersion": "0.2",
        "name": "Locust",
        "computerType": "public",
        "timestampCreated": None,
        "timestampUpdated": None
      }
    ]

    settings_gets = [
      "%7B%22solutions%22%3A%5B%7B%22id%22%3A%22com.microsoft.windows.desktopBackground%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.desktopBackgroundColor%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mirrorScreen%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.cursors%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.colorFilters%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.filterKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.highContrast%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.audioDescription%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.notificationDuration%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.language%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.toggleKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.underlineMenuShortcuts%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.shortcutWarningMessage%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.shortcutWarningSound%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.magnifier%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseSettings%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseTrailing%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.narrator%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.nightScreen%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.soundSentry%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.onscreenKeyboard%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenDPI%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenResolution%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.stickyKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.touchPadSettings%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.typingEnhancement%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.volumeControl%22%7D%2C%7B%22id%22%3A%22net.gpii.test.speechControl%22%7D%2C%7B%22id%22%3A%22net.gpii.explode%22%7D%2C%7B%22id%22%3A%22net.gpii.uioPlus%22%7D%2C%7B%22id%22%3A%22trace.easyOne.communicator.windows%22%7D%2C%7B%22id%22%3A%22trace.easyOne.sudan.windows%22%7D%2C%7B%22id%22%3A%22webinsight.webAnywhere.windows%22%7D%2C%7B%22id%22%3A%22com.microsoft.office%22%7D%5D%2C%22OS%22%3A%7B%22id%22%3A%22win32%22%2C%22version%22%3A%2210.0.18362%22%7D%7D"
    ]

    settings_puts = [
      {
          "contexts": {
              "gpii-default": {
                  "preferences": {
                      "http://registry.gpii.net/common/DPIScale": 2
                  }
              }
          }
      },
      {
          "contexts": {
              "gpii-default": {
                  "preferences": {
                      "http://registry.gpii.net/common/DPIScale": 2,
                      "http://registry.gpii.net/common/highContrastTheme": "white-black",
                      "http://registry.gpii.net/applications/com.microsoft.windows.colorFilters": {
                          "FilterType": 4
                      },
                      "http://registry.gpii.net/common/volume": 0.713
                  }
              }
          }
      }
    ]

    def __init__(self):
        self.username = "locust" + str(randint(1,10000))
        self.client_id = os.getenv('MORPHIC_CLIENT_ID')
        self.client_secret = os.getenv('MORPHIC_CLIENT_SECRET')
        self.basic_auth_user = os.getenv('BASIC_AUTH_USER')
        self.basic_auth_password = os.getenv('BASIC_AUTH_PASSWORD')

def on_failure(request_type, name, response_time, response_length, exception, **kwargs):
    print("Request: %s %s" % (request_type, name))
    if exception.request is not None:
        print("URL: %s" % (exception.request.url))
    print("Exception: %s" % (exception))
    if exception.response is not None:
        print("Code: %s" % (exception.response.status_code))
        print("Headers: %s" % (exception.response.headers))
        print("Content: %s" % (exception.response.content))