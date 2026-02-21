# Xcode Cloud 設定メモ

## 目的
Xcode Cloud でのビルド時に以下のエラーが出る場合の対処です。

- `could not find included file 'Generated.xcconfig'`
- `Unable to load contents of file list: ... Pods-Runner-*-input-files.xcfilelist`

これらは `flutter pub get` / `pod install` が実行されていないことが主因です。

## 設定手順（Xcode Cloud）
Flutter 公式ドキュメントの構成に合わせて設定します。

1. Xcode Cloud の Workflow 設定を開く
2. **Post-Clone Script** に以下を設定
   - `ios/ci_scripts/ci_post_clone.sh`
3. 環境変数に `GOOGLESERVICE_INFO_PLIST_BASE64` を追加
   - 値は `GoogleService-Info.plist` を base64 変換したもの

## スクリプト内容
`ios/ci_scripts/ci_post_clone.sh` が以下を実行します。
- `flutter pub get`
- `pod install`

## Base64 からの復元
Xcode Cloud の環境変数 `GOOGLESERVICE_INFO_PLIST_BASE64` を使って復元します。

```
echo "$GOOGLESERVICE_INFO_PLIST_BASE64" | base64 --decode > ios/Runner/GoogleService-Info.plist
```
