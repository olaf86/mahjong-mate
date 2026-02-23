# Firebase App Check 監視導入手順（enforce なし）

この手順は、App Check を「監視目的」で導入し、`enforceAppCheck` はまだ有効化しない前提です。

## 目的

- 不正クライアント起点の呼び出し傾向を可視化する
- 本番影響なく App Check トークン発行率を確認する
- 将来 `enforceAppCheck: true` に切り替えるための判断材料を集める

## 1. Firebase Console で App Check を有効化

1. Firebase Console を開く
2. 対象プロジェクト: `mahjong-mate-app`
3. `App Check` で各アプリを登録
   - Android: Play Integrity
   - iOS/macOS: App Attest（必要に応じて DeviceCheck fallback）
   - Web（必要な場合）: reCAPTCHA v3

注意:
- この時点では、Firestore / Auth / Functions の `Enforce` は **有効化しない**

## 2. Flutter 側の最低実装

1. `pubspec.yaml` に依存追加

```yaml
dependencies:
  firebase_app_check: ^0.4.1+1
```

2. `lib/main.dart` の Firebase 初期化直後に App Check 有効化を追加

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

await Firebase.initializeApp();
await FirebaseAppCheck.instance.activate(
  providerAndroid: const AndroidPlayIntegrityProvider(),
  providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
);
```

補足:
- Debug ビルドでは Debug Provider を使う（開発端末のトークンを Console 側で許可）

## 3. リリースして監視する

1. 内部テスト or クローズドテストへ配布
2. Firebase Console `App Check` で以下を確認
   - 有効トークンの割合
   - 未検証リクエストの傾向
   - サービス別（Firestore / Functions）のリクエスト状況

## 4. 監視時の判定基準（例）

- 1〜2週間で主要トラフィックの大半が有効トークン化される
- 正規ユーザーでエラー報告が増えていない
- 特定OS/端末で偏った失敗がない

## 5. enforce へ進む条件

- 上記が満たせたら段階的に enforcement を検討
- 例: まず Callable Function の一部のみ `enforceAppCheck: true`

## 6. ローカルデバッグ（iOS Simulator）

Firebase 公式の iOS Debug Provider 手順に合わせて、`ios/Runner/AppDelegate.swift` で
`DEBUG + Simulator` のときだけ `AppCheckDebugProvider` を使う設定を入れています。

ローカル確認手順:

1. iOS Simulator で Debug 実行
2. Xcode ログに出る App Check debug token を確認
3. Firebase Console の App Check で debug token を登録
4. 再実行して App Check エラーが解消されることを確認
