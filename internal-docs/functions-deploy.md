# Cloud Functions デプロイ手順（`functions/index.js`）

`deleteAccountData`（Callable Function）をデプロイするための手順です。

## 前提

- Firebase CLI がインストール済み
- `firebase login` 済み
- 対象プロジェクトが `mahjong-mate-app`（`.firebaserc`）

## 初回セットアップ

1. ルートで依存解決

```bash
flutter pub get
```

2. Functions 依存をインストール

```bash
cd functions
npm install
cd ..
```

## デプロイ

`deleteAccountData` のみをデプロイする場合:

```bash
firebase deploy --only functions:deleteAccountData
```

Functions 全体をデプロイする場合:

```bash
firebase deploy --only functions
```

## 動作確認（推奨）

1. アプリでログイン済みユーザーを用意
2. 認証画面の「アカウント削除」を実行
3. Firebase Console で以下を確認
- `rule_sets` の当該 `ownerUid` データが削除されている
- `collectionGroup(follows)` で `ruleSetOwnerUid == uid` が削除されている
- `users/{uid}` ドキュメント配下が削除されている
- Firebase Authentication の該当ユーザーが削除されている

## 補足（セキュリティ）

- Callable Function の `request.auth.uid` は Firebase が検証した ID トークン由来です。
- 通常運用ではクライアントが任意のUIDを偽装して送ることはできません。
- ただし「誰でも呼べる」点は変わらないため、Function 側で `request.auth` チェックは必須です。
- 必要に応じて App Check の `enforceAppCheck` を有効化して、未検証クライアントからの呼び出しを抑止できます。
