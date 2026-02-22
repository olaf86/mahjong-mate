# GitHub Pages でプライバシーポリシーを公開する手順

この手順は、`docs/privacy-policy.md` を GitHub Pages で公開し、Google Play Console のプライバシーポリシー URL に設定するまでを対象にしています。

## 前提

- GitHub リポジトリ: `olaf86/mahjong_mate`
- 公開したいファイル: `docs/privacy-policy.md`
- ブランチ: `main`（公開元として利用）

## 1. 変更を main に反映する

1. 作業ブランチで変更をコミットする
2. GitHub に Push する
3. Pull Request を作成して `main` にマージする

`docs/privacy-policy.md` が `main` に存在していることを確認してください。

## 2. GitHub Pages を有効化する

1. GitHub の対象リポジトリを開く
2. `Settings` → `Pages` を開く
3. `Build and deployment` の `Source` で `Deploy from a branch` を選択
4. `Branch` で `main` を選択
5. フォルダで `/docs` を選択
6. `Save` を押す

反映に数分かかることがあります。

## 3. 公開 URL を確認する

このリポジトリ構成では、以下の URL で公開されます。

- `https://olaf86.github.io/mahjong_mate/privacy-policy.html`

確認ポイント:

- ブラウザで URL を開いて本文が表示される
- 最終更新日が意図した日付になっている
- スマホ表示でも読める

## 4. Google Play Console に設定する

1. Google Play Console を開く
2. 対象アプリを選択
3. `アプリのコンテンツ`（またはポリシー関連設定）を開く
4. プライバシーポリシー URL に下記を入力
   - `https://olaf86.github.io/mahjong_mate/privacy-policy.html`
5. 保存して審査提出フローを進める

## 5. 文面を更新するときの運用

1. `docs/privacy-policy.md` を更新
2. `main` にマージ
3. 数分待って同一 URL で反映確認

URL は変えずに運用するのが推奨です。

## トラブルシュート

- 404 になる:
  - `Settings > Pages` で `main` + `/docs` になっているか確認
  - `privacy-policy.md` のファイル名が一致しているか確認
  - 反映待ち（数分）後に再読込
- 古い内容が表示される:
  - ブラウザのキャッシュを削除して再読込
  - `main` に変更がマージ済みか確認

