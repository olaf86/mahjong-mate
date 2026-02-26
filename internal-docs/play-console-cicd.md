# Play Console CI/CD

## 目的

- `main` への push で Android AAB を自動ビルドし、Artifact を取得できるようにする
- 必要時に手動で Google Play Console へアップロードできるようにする

## 対象 Workflow

- `mahjong_mate/.github/workflows/android-build-artifact.yml`
  - `main` push 時に AAB をビルドして Artifact 化
- `mahjong_mate/.github/workflows/android-publish-play.yml`
  - `workflow_dispatch` で手動実行し、Play Console の指定トラックへアップロード

## GitHub Secrets

以下を Repository Secrets に登録する。

1. `ANDROID_GOOGLE_SERVICES_JSON`
2. `ANDROID_KEY_PROPERTIES`
3. `ANDROID_UPLOAD_KEYSTORE`
4. `PLAY_SERVICE_ACCOUNT_JSON`

`PLAY_SERVICE_ACCOUNT_JSON` は base64 ではなく JSON 生文字列をそのまま登録する。

## Secrets 作成手順（ローカル）

### 1) google-services.json

```bash
base64 -i android/app/google-services.json | pbcopy
```

貼り付け先: `ANDROID_GOOGLE_SERVICES_JSON`

### 2) key.properties

```bash
base64 -i android/key.properties | pbcopy
```

貼り付け先: `ANDROID_KEY_PROPERTIES`

### 3) upload keystore (.jks)

```bash
base64 -i android/mahjong_mate_upload_key.jks | pbcopy
```

貼り付け先: `ANDROID_UPLOAD_KEYSTORE`

### 4) Play Console サービスアカウント JSON

- Google Cloud でサービスアカウントキー(JSON)を発行
- Play Console の API アクセスで当該サービスアカウントに権限付与
- JSON ファイル内容をそのまま `PLAY_SERVICE_ACCOUNT_JSON` に登録

## 注意事項

- `android/key.properties` の `storeFile` は `mahjong_mate_upload_key.jks` 前提。
- workflow 内では `android/mahjong_mate_upload_key.jks` として復元するため、`storeFile` と一致している必要がある。
- 本番配布前は `internal` トラックでの動作確認を推奨。
