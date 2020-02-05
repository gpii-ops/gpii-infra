import os
from random import randint

class MorphicCommon:
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

        client_id = os.getenv('MORPHIC_CLIENT_ID')
        if not client_id:
            client_id = '05388544-a7af-4377-a18a-b29ce68211c5'
        self.client_id = client_id

        client_secret = os.getenv('MORPHIC_CLIENT_SECRET')
        if not client_secret:
            client_secret = '19d93ac9-d274-499e-b85d-13c5ceda188e'
        self.client_secret = client_secret

def on_failure(request_type, name, response_time, response_length, exception, **kwargs):
    print("Request: %s %s" % (request_type, name))
    if exception.request is not None:
        print("URL: %s" % (exception.request.url))
    print("Exception: %s" % (exception))
    if exception.response is not None:
        print("Code: %s" % (exception.response.status_code))
        print("Headers: %s" % (exception.response.headers))
        print("Content: %s" % (exception.response.content))
