# Local Screenshot Automation (Maestro + Firebase Emulator)

## 目的

- 実DBとは完全に分離した状態で、ローカルでスクリーンショットを自動取得する。
- Android / iOS の両方で同じ撮影フローを再利用する。

## 構成

- UI操作: Maestro
- データ保存先: Firebase Emulator (Auth / Firestore / Functions)
- アプリ起動: `flutter run` + `--dart-define=USE_FIREBASE_EMULATORS=true`

この構成により、撮影時のデータはすべてローカルエミュレータ内に閉じる。

## 事前準備

1. Firebase CLI をインストール
2. Maestro CLI をインストール
3. Android Emulator または iOS Simulator を起動

## 使うフラグ

- `USE_FIREBASE_EMULATORS=true`
  - FirebaseAuth / Firestore / Functions を emulator に接続する
- `SCREENSHOT_MODE=true`
  - スクリーンショット用途の実行モード識別用（将来の分岐追加用）

実装上、`USE_FIREBASE_EMULATORS=true` のときは App Check を有効化しない。

## Android 実行手順

### 1. Firebase Emulator を起動

```bash
firebase emulators:start --only auth,firestore,functions
```

### 2. アプリを emulator 向けに起動

```bash
flutter run \
  -d emulator-5554 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SCREENSHOT_MODE=true
```

### 3. Maestro フロー実行

```bash
maestro test maestro/flows/android/store_screenshots.yaml
```

## iOS 実行手順

### 1. Firebase Emulator を起動

```bash
firebase emulators:start --only auth,firestore,functions
```

### 2. アプリを simulator 向けに起動

```bash
flutter run \
  -d "iPhone 15 Pro" \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SCREENSHOT_MODE=true
```

### 3. Maestro フロー実行

```bash
maestro test maestro/flows/ios/store_screenshots.yaml
```

## ダミーデータ方針

- 基本は Maestro フロー内の入力操作でダミーデータを作る。
- 既存データに依存しないように `launchApp.clearState: true` を使う。
- より厳密に固定したい場合は、後続で Firestore Emulator の import/export を導入する。

## トラブルシュート

- 本番DBに接続されてしまう
  - `flutter run` の `--dart-define=USE_FIREBASE_EMULATORS=true` を確認する。
- Android で emulator に接続できない
  - Android は host が `10.0.2.2` である必要がある。
- スクショが期待通りの画面で止まらない
  - Maestro flow の `assertVisible` と `scrollUntilVisible` を増やして同期を強める。
