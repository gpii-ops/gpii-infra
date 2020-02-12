# Testing 

This document describes pointers and notes for testing the GPII infrastructure in different contexts.

## End-to-End Manual Testing Tutorial

This section contains a tutorial to test the frontend Morphic application against the backend. Relevant calls against the backend are noted after each action.

### Setting Up Morphic

#### Using a Development Version of the Morphic Client

1. Obtain a copy of the gpii/gpii-app repository:

```bash
$ git clone https://github.com/GPII/gpii-app.git

```

2. Create a new configuration in `configs/app.cloud.json`, containing the following contents:

```
{
    "type": "gpii.appWithTaskTray",
    "options": {
        "gradeNames": ["fluid.component"],
        "distributeOptions": {}
    },
    "mergeConfigs": [
        "%gpii-app/configs/app.base.json",
        "%gpii-universal/gpii/configs/gpii.config.untrusted.development"
     ]
}
```

3. Spin up the vagrant box:

```bash
$ cd gpii-app

$ vagrant up
```

4. When the machine is up and running, open a command prompt and run the application:

```
$ v:

$ SET GPII_CLOUD_URL=http://flowmanager.<CLUSTER_DNS>

$ node_modules\.bin\electron . configs app.cloud

...

```

#### Manual Installation and Configuration of the Morphic Client

You can find the Morphic Installers in our [shared Google Drive](https://drive.google.com/drive/u/1/folders/1nzXsW83qRejup3D_yVYO9t5i4lKN_p5G).  Please note, this link will only work if you are logged in using a Google account that has permission.

Run the installer you want to test.  When installation is finished, you will need to manually configure the client to use your dev cloud.

1. Edit `C:\Program Files (x86)\Morphic\windows\service.json5`
1. Update the `GPII_CLOUD_URL` setting to point to your dev cloud, i.e. `https://flowmanager.<username>.dev.gcp.gpii.net`
1. To avoid errors with the self-signed certificates used in a dev cloud, add a new `NODE_TLS_REJECT_UNAUTHORIZED` and set it to `0`. 
1. Restart, either by:
   1. Restarting windows
   1. Opening PowerShell as an administrator and running `restart-service "morphic service"`

#### Setting Up Credentials

If you wish to actually save to the cloud, you will need to create credentials that can be used with your client:

1. Check out the `universal` repository, i.e. `git clone https://github.com/GPII/universal`.
1. Install the package's dependencies, i.e. `cd universal && npm install`.
1. Generate auto-key in credentials, using a command like `cd scripts && GPII_CREDENTIALS_NAME="GPII Testers" GPII_CREDENTIALS_SITE=testers.gpii.net node generateCredentials.js`
1. A directory will be created containing two files.  One is the CouchDB data for your credentials.  The other is the "secret" file for the client itself.
1. Edit the generated `couchDBData.json` file and enable the two write settings:
   1. `"isCreateGpiiKeyAllowed": true,`
   1. `"isCreatePrefsSafeAllowed": true,`
1. From the `gcp/live/dev` directory in your copy of the `gpii-infra` repository, run `rake couchdb_ui`.  Keep the window open, you will need the information displayed onscreen in the next command.
1. Upload the credentials you created using a command like:  `curl -d @couchDBData.json -H "Content-type: application/json" -X POST  http://ui:<PASSWORD>@localhost:35984/gpii/_bulk_docs`
1. On the machine where your client is installed, save the `secret.txt` file you generated above to `C:\ProgramData\Morphic Credentials\secret.txt`.
1. Restart, either by:
   1. Restarting windows
   1. Opening PowerShell as an administrator and running `restart-service "morphic service"`
1. The Morphic icon in the task bar should now turn green shortly after startup. (The colours are different in some contrast schemes, you can also click "My Saved Settings" in the QSS.  If you're logged in, you will see a like to re-apply the preferences stored in the cloud.

#### Viewing the Logs for a Single Login

When a user logs in, two calls should be registered against the cloud-based flow manager. You can use the `kubectl` command to view the logs on either the ingress controller or the flowmanager pods:

```
$ kubectl logs -n gpii -l app=flowmanager
...
10.16.0.3 - [10.16.0.3] - - [10/Sep/2018:13:04:07 +0000] "POST /access_token HTTP/1.1" 200 90 "-" "-" 308 0.168 [gpii-flowmanager-80] 10.17.1.10:8081 90 0.136 200 7fc8385cfb9bc2cd6bb6ebfc2b5a7ee5
...
```

The first call logged above retrieves the OAuth bearer token used in subsequent calls.

```
$ kubectl logs -n gpii -l app=flowmanager
...
10.16.0.3 - [10.16.0.3] - - [10/Sep/2018:13:05:43 +0000] "GET /carla/settings/%7B%22solutions%22%3A%5B%7B%22id%22%3A%22net.gpii.test.speechControl%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.interface%22%7D%2C%7B%22id%22%3A%22fakemag2%22%7D%2C%7B%22id%22%3A%22fakescreenreader1%22%7D%2C%7B%22id%22%3A%22org.gnome.nautilus%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.keyboard%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.applications.onscreen-keyboard%22%7D%2C%7B%22id%22%3A%22org.gnome.orca%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.magnifier%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.magnifier%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.onscreenKeyboard%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.narrator%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.highContrast%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.highContrastTheme%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.stickyKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.filterKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseTrailing%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenDPI%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.cursors%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenResolution%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.nightScreen%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.typingEnhancement%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.language%22%7D%2C%7B%22id%22%3A%22com.android.activitymanager%22%7D%2C%7B%22id%22%3A%22com.android.talkback%22%7D%2C%7B%22id%22%3A%22com.android.freespeech%22%7D%2C%7B%22id%22%3A%22com.android.settings.secure%22%7D%2C%7B%22id%22%3A%22com.android.audioManager%22%7D%2C%7B%22id%22%3A%22com.android.persistentConfiguration%22%7D%2C%7B%22id%22%3A%22org.alsa-project%22%7D%2C%7B%22id%22%3A%22org.freedesktop.xrandr%22%7D%2C%7B%22id%22%3A%22com.android.settings.system%22%7D%2C%7B%22id%22%3A%22net.gpii.uioPlus%22%7D%2C%7B%22id%22%3A%22net.gpii.explode%22%7D%5D%2C%22OS%22%3A%7B%22id%22%3A%22win32%22%2C%22version%22%3A%2210.0.16299%22%7D%7D HTTP/1.1" 200 38362 "-" "-" 2145 0.280 [gpii-flowmanager-80] 10.17.1.10:8081 38362 0.250 200 0e1061c44f8963b44399eb245e613d30
...
```

The second call logged above requests the settings for the device.

### Testing Cloud Saves

For this to work, you must be logged in as a real user (see the "auto key in" installation instructions above).  The Morphic icon in the task bar should be green, and there should be no errors displayed.

Here is a basic example of changing and saving a setting:

    1. Click the Morphic icon (green gear) in your taskbar. The Quickset Strip (QSS) will appear. 
    2. Click the "Screen Zoom" button, a sub-panel will open.
    3. Click the "+ Larger" button in the sub-panel.
    4. Click the "Save" button on the right side of the QSS.
    5. Morphic should report "Your settings were saved to the Moprhic Cloud"

You should be able to verify that additional requests were made to the backend to store these preferences using the kubectl commands above.

### Production Config Tests

Another way to exercise the front-end nodejs code against a cloud based backend is to run the productionConfigTests. As of September 10, 2018, these productionConfigTests only exercise login and logout. To execute them, run the following test script from the universal container. Make sure to use an appropriate version. Generally, the latest version can be found in `shared/versions.yml`, which is automatically kept up to date.

```
$ docker run --rm --name productionConfigTests -e GPII_CLOUD_URL=https://flowmanager.<CLUSTER_DNS> gpii/universal@sha256:bc92279591c0ab60d11ecf55e43f783cd7cb92a0bc2fea6661054a065bbb2e49 node tests/ProductionConfigTests.js

...
14:18:42.191:  Creating GPII settings directory in /tmp/gpii
14:18:42.196:  jq: Test concluded - Module "gpii.config.untrusted.development tests" Test name "Flow Manager development tests": 2/2 passed - PASS
14:18:42.198:  jq: ***************
14:18:42.198:  jq: All tests concluded: 2/2 total passed in 1542ms - PASS
14:18:42.198:  jq: ***************

```

On the backend, we should expect the following log entries to be made for the ingress:

```
10.16.0.2 - [10.16.0.2] - - [10/Sep/2018:14:19:51 +0000] "POST /access_token HTTP/1.1" 200 90 "-" "-" 312 0.146 [gpii-flowmanager-80] 10.17.1.10:8081 90 0.113 200 7c63c0b04856e04bad6872e8f28884f1
10.16.0.3 - [10.16.0.3] - - [10/Sep/2018:14:24:00 +0000] "GET /testUser1/settings/%7B%22solutions%22%3A%5B%7B%22id%22%3A%22net.gpii.test.speechControl%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.interface%22%7D%2C%7B%22id%22%3A%22fakemag2%22%7D%2C%7B%22id%22%3A%22fakescreenreader1%22%7D%2C%7B%22id%22%3A%22org.gnome.nautilus%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.keyboard%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.applications.onscreen-keyboard%22%7D%2C%7B%22id%22%3A%22org.gnome.orca%22%7D%2C%7B%22id%22%3A%22org.gnome.desktop.a11y.magnifier%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.magnifier%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.onscreenKeyboard%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.narrator%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.highContrast%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.highContrastTheme%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.stickyKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.filterKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseKeys%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.mouseTrailing%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenDPI%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.cursors%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.screenResolution%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.nightScreen%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.typingEnhancement%22%7D%2C%7B%22id%22%3A%22com.microsoft.windows.language%22%7D%2C%7B%22id%22%3A%22com.android.activitymanager%22%7D%2C%7B%22id%22%3A%22com.android.talkback%22%7D%2C%7B%22id%22%3A%22com.android.freespeech%22%7D%2C%7B%22id%22%3A%22com.android.settings.secure%22%7D%2C%7B%22id%22%3A%22com.android.audioManager%22%7D%2C%7B%22id%22%3A%22com.android.persistentConfiguration%22%7D%2C%7B%22id%22%3A%22org.alsa-project%22%7D%2C%7B%22id%22%3A%22org.freedesktop.xrandr%22%7D%2C%7B%22id%22%3A%22com.android.settings.system%22%7D%2C%7B%22id%22%3A%22net.gpii.uioPlus%22%7D%2C%7B%22id%22%3A%22net.gpii.explode%22%7D%5D%2C%22OS%22%3A%7B%22id%22%3A%22linux%22%2C%22version%22%3A%223.10.0-862.el7.x86-64%22%7D%7D HTTP/1.1" 200 18570 "-" "-" 2160 0.237 [gpii-flowmanager-80] 10.17.1.10:8081 18570 0.237 200 39a38afe8ca911e5f15c3cd2906af73b
```

In addition, the flowmanager calls the preferences server and similar logs entries should be found in the preferences pod:

```
14:24:00.021:  Invoking handler gpii.preferencesServer.get.handler for route /preferences/:gpiiKey with expectedGrade kettle.request.http
14:24:00.025:  Kettle server allocated request object with type gpii.preferencesServer.get.handler
14:24:00.025:  gpii.preferencesServer.getPreferences called - fetching preferences for the GPII key testUser1
14:24:00.025:  DataSource Issuing HTTP request with options {
    "port": "5984",
    "method": "GET",
    "headers": {

    },
    "protocol": "http:",
    "auth": "9af19d4cc412590b61e2440ce29eff2c:72e93ea87d01b2685950c01354e9ec70",
    "host": "couchdb-svc-couchdb.gpii.svc.cluster.local:5984",
    "hostname": "couchdb-svc-couchdb.gpii.svc.cluster.local",
    "path": "/gpii/_design/views/_view/findPrefsSafeByGpiiKey?key=%22testUser1%22&include_docs=true",
    "termMap": {
        "gpiiKey": "%gpiiKey",
        "baseUrl": "noencode:%baseUrl",
        "port": "%port",
        "dbName": "%dbName"
    },
    "url": "%baseUrl:%port/%dbName/_design/views/_view/findPrefsSafeByGpiiKey?key=%22%gpiiKey%22&include_docs=true",
    "directModel": {
        "baseUrl": "http://9af19d4cc412590b61e2440ce29eff2c:72e93ea87d01b2685950c01354e9ec70@couchdb-svc-couchdb.gpii.svc.cluster.local",
        "port": "5984",
        "dbName": "gpii",
        "gpiiKey": "testUser1"
    },
    "operation": "get",
    "reverse": false,
    "writeMethod": "PUT",
    "notFoundIsEmpty": true
}
14:24:00.097:  Preferences Server, getPreferences(), returning preferences: {
    "contexts": {
        "gpii-default": {
            "name": "Default preferences",
            "preferences": {
                "http://registry.gpii.net/common/setting1": 12,
                "http://registry.gpii.net/common/setting2": "white",
                "http://registry.gpii.net/common/setting3": "black",
                "http://registry.gpii.net/common/setting4": [
                    "Comic Sans"
                ],
                "http://registry.gpii.net/common/setting5": "sans serif",
                "http://registry.gpii.net/common/setting6": false
            }
        }
    },
    "name": undefined
}
```

The above functionality is a limited test suite that needs to be expanded to be more complete. Work is being tracked in [GPII-3333](https://issues.gpii.net/browse/GPII-3333) for that.

## Performance Testing

Currently, the "preferences read" tests are run regularly against production, and as part of the [continuous deployment pipeline](CI-CD.md).

When you are testing changes to the cloud, you are expected to run the same  tests and confirm that:

1. Performance is not unacceptably degraded by your changes.
2. There are no unexpected errors introduced by your changes.

See the "Locust" section of the [README](README.md) for more details on running these tests.

## Security Testing

_TODO_
