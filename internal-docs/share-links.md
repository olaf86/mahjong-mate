# Share Links Setup

This app uses universal/app links for `https://mahjong-mate-app.web.app/r/{shareCode}`.

## iOS (Universal Links)

1. Ensure `Runner.entitlements` includes:

```
applinks:mahjong-mate-app.web.app
```

2. Host `apple-app-site-association` at:

```
https://mahjong-mate-app.web.app/.well-known/apple-app-site-association
```

Example (replace TEAM_ID):

```
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.dev.asobo.mahjongmate",
        "paths": ["/r/*"]
      }
    ]
  }
}
```

## Android (App Links)

1. Intent filter is in `android/app/src/main/AndroidManifest.xml`:

```
https://mahjong-mate-app.web.app/r/*
```

2. Host `assetlinks.json` at:

```
https://mahjong-mate-app.web.app/.well-known/assetlinks.json
```

Example (replace SHA256 fingerprints):

```
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "dev.asobo.mahjongmate",
      "sha256_cert_fingerprints": [
        "REPLACE_WITH_PLAY_APP_SIGNING_SHA256",
        "REPLACE_WITH_UPLOAD_KEY_SHA256_IF_NEEDED"
      ]
    }
  }
]
```

## Android verification

1. Deploy latest hosting content (including `.well-known/assetlinks.json`).
2. Install app build signed with the certificate listed in `assetlinks.json`.
3. Confirm connected device/emulator:

```bash
adb devices
```

4. Verify app links status on device:

```bash
adb shell pm get-app-links dev.asobo.mahjongmate
```

5. Trigger deep link:

```bash
adb shell am start -a android.intent.action.VIEW -d "https://mahjong-mate-app.web.app/r/ABCD"
```
