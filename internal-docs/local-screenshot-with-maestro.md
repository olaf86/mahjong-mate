# Local Screenshot Automation (Maestro + Firebase Emulator)

## 目的

- 実DBとは完全に分離した状態で、ローカルでスクリーンショットを自動取得する。
- Android / iOS の両方で同じ撮影フローを再利用する。

## 構成

- UI操作: Maestro
- データ保存先: Firebase Emulator (Auth / Firestore / Functions)
- アプリ起動: `flutter run` + `--dart-define=USE_FIREBASE_EMULATORS=true`

この構成により、撮影時のデータはすべてローカルエミュレータ内に閉じる。

## 成果物の出力先

- Android: `artifacts/store_screenshots/android/`
- iOS: `artifacts/store_screenshots/ios/`
- iPad: `artifacts/store_screenshots/ios_ipad/`

`takeScreenshot` の保存先を flow で固定しているため、プロジェクトルート直下に散らばらない。

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

## 実行時の注意

- スクリーンショット取得時は、iOS Simulator と Android Emulator を同時に起動しない。
- `flutter run` は毎回対象デバイスを1つに固定して実行する（`-d` を必ず指定）。

## Android 実行手順

### 1. Firebase Emulator を起動

```bash
firebase emulators:start --project mahjong-mate-app --only auth,firestore,functions
```

### 2. スクリーンショット用ダミーデータを投入

```bash
(cd functions && npm run seed:screenshot)
```

投入されるシナリオ例:
- 友だちと週末麻雀
- サークル標準ルール
- 大会向け競技ルール
- ローカルハウスルール

### 3. アプリを emulator 向けに起動

```bash
flutter run \
  -d emulator-5554 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SCREENSHOT_MODE=true \
  --dart-define=SCREENSHOT_AUTH_EMAIL=screenshot@example.com \
  --dart-define=SCREENSHOT_AUTH_PASSWORD=Passw0rd!
```

### 4. Maestro フロー実行

```bash
maestro test maestro/flows/android/store_screenshots.yaml
```

または、seed から自動でまとめて実行:

```bash
./scripts/run_screenshots_android.sh
```

## iOS 実行手順

### 1. Firebase Emulator を起動

```bash
firebase emulators:start --project mahjong-mate-app --only auth,firestore,functions
```

### 2. スクリーンショット用ダミーデータを投入

```bash
(cd functions && npm run seed:screenshot)
```

### 3. アプリを simulator 向けに起動

```bash
flutter run \
  -d "iPhone 11 Pro Max" \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SCREENSHOT_MODE=true \
  --dart-define=SCREENSHOT_AUTH_EMAIL=screenshot@example.com \
  --dart-define=SCREENSHOT_AUTH_PASSWORD=Passw0rd!
```

### 4. Maestro フロー実行

```bash
maestro test maestro/flows/ios/store_screenshots.yaml
```

または、seed から自動でまとめて実行:

```bash
./scripts/run_screenshots_ios.sh
```

## iPad 実行手順

### 1. Firebase Emulator を起動

```bash
firebase emulators:start --project mahjong-mate-app --only auth,firestore,functions
```

### 2. スクリーンショット用ダミーデータを投入

```bash
(cd functions && npm run seed:screenshot)
```

### 3. アプリを iPad simulator 向けに起動

```bash
flutter run \
  -d "iPad Pro (12.9-inch) (6th generation)" \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SCREENSHOT_MODE=true \
  --dart-define=SCREENSHOT_AUTH_EMAIL=screenshot@example.com \
  --dart-define=SCREENSHOT_AUTH_PASSWORD=Passw0rd!
```

### 4. Maestro フロー実行

```bash
maestro test maestro/flows/ios/store_screenshots_ipad.yaml
```

または、seed から自動でまとめて実行:

```bash
./scripts/run_screenshots_ipad.sh
```

## ダミーデータ方針

- ダミーデータは seed スクリプトで事前投入する。
- Maestro フローは入力最小化（画面遷移と撮影のみ）にする。
- 既存データに依存しないように `launchApp.clearState: true` を使う。
- より厳密に固定したい場合は、後続で Firestore Emulator の import/export を導入する。

## トラブルシュート

- 本番DBに接続されてしまう
  - `flutter run` の `--dart-define=USE_FIREBASE_EMULATORS=true` を確認する。
- Android で emulator に接続できない
  - Android は host が `10.0.2.2` である必要がある。
- スクショが期待通りの画面で止まらない
  - Maestro flow の `assertVisible` と `scrollUntilVisible` を増やして同期を強める。
