# Firebase セットアップ手順（iOS + Android）

このアプリは Firestore を利用します。以下の順で Firebase を準備してください。

1. Firebase プロジェクトを作成
1. Android アプリを追加
1. iOS アプリを追加
1. 設定ファイルを配置
1. Firestore を有効化

## 1. Firebase プロジェクト作成
Firebase コンソールで新規プロジェクトを作成します。

## 2. Android アプリ追加
- パッケージ名: `com.example.mahjong_mate`
- `google-services.json` をダウンロード
- `mahjong_mate/android/app/google-services.json` に配置

## 3. iOS アプリ追加
- iOS Bundle ID: `com.example.mahjongMate` など任意
- `GoogleService-Info.plist` をダウンロード
- `mahjong_mate/ios/Runner/GoogleService-Info.plist` に配置

注意: iOS の Bundle ID を変更する場合は `ios/Runner.xcodeproj` でも一致させてください。

## 4. Firestore を有効化
Firebase コンソールで Cloud Firestore を有効化してください。

## 5. 初期データ例
Firestore の `rule_sets` コレクションに以下の形式でドキュメントを入れると、
一覧画面に反映されます。

```json
{
  "name": "メインコミュニティ採用ルール",
  "description": "オンラインと雀荘で共有している標準ルールセット。",
  "ownerName": "Mahjong Mate",
  "ownerDeviceId": "device-id",
  "shareCode": "MJM-2107",
  "visibility": "public",
  "updatedAt": "timestamp",
  "items": [
    {
      "id": "basic-1",
      "category": "basic",
      "title": "喰いタンあり・後付けなし",
      "description": "鳴きタンは許可、後付けは不可。",
      "priority": 2
    }
  ]
}
```
