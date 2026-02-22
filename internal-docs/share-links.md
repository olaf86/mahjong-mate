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

Example (replace TEAM_ID if needed):

```
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "48C76HC76Y.com.example.mahjongMate",
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

Example (replace SHA256 fingerprint when available):

```
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.mahjong_mate",
      "sha256_cert_fingerprints": [
        "REPLACE_WITH_SHA256_CERT_FINGERPRINT"
      ]
    }
  }
]
```
