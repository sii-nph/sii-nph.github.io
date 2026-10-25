# sii-nph.github.io

これまで描いたアナログの絵をまとめた、sii-nph のポートフォリオサイトです。
作品を一覧で見ることで、作風が把握できることを目的としています。

公開URL: https://sii-nph.github.io/

## 技術構成

- [Jekyll](https://jekyllrb.com/)(GitHub Pages 標準)
- 公開は GitHub Pages の「`main` ブランチ / ルート」から。`main` に push すると、数分後に自動で反映されます
- JavaScript は、作品の拡大表示と、スクロールに応じた作品の大きさの切り替えのみ(最小限)
- 配色は白と明るい色を基調に、アクセントは新橋色です(ダークモードはありません)

## ディレクトリ構成

```
Gemfile                  # github-pages gem など
_config.yml              # Jekyll 設定
_layouts/default.html    # 共通レイアウト
_data/works.yml          # 作品データ(1作品 = 1エントリ)
_tools/make-images.ps1   # 元画像から公開用の本画像を作るスクリプト
_tools/jekyll.sh         # WSL 上で Jekyll を実行するスクリプト(install / serve / build)
_inbox/                  # 元画像の置き場(公開されない・git にも入らない)
assets/css/style.css     # スタイル
assets/js/feed.js        # 作品一覧のスクロール演出(中央の作品を大きく表示)
assets/js/lightbox.js    # 拡大表示(最小限の JS)
assets/images/works/     # 本画像(長辺 1600px)
index.html               # _data/works.yml から作品一覧を生成
CLAUDE.md                # Claude Code 向けの作業ルール
```

## 作品の追加手順

1. 元画像を `_inbox/` に入れます(加工は不要です)
2. 公開用の画像を作ります。縦横比は保たれ、切り抜きはされません。位置情報などの EXIF も残りません
   ```powershell
   powershell -ExecutionPolicy Bypass -File _tools\make-images.ps1 -Source "_inbox\元画像.jpg" -Name 2024-03
   ```
   - 本画像(長辺 1600px)が `assets/images/works/` に出力されます(サムネイルはありません。一覧にも拡大表示にも本画像を使います)
   - `-Name` は `YYYY-NN`(制作年と、同じ年の通し番号)です
   - スキャナーの背景(灰緑色)が写っている場合は、`-Crop "left,top,right,bottom"`(元画像の px)で紙の端まで切り詰めます。紙の端から約 60px 内側を指定すると、影や灰色が残りません。絵そのものは切りません
     ```powershell
     powershell -ExecutionPolicy Bypass -File _tools\make-images.ps1 -Source "_inbox\scan-003.jpg" -Name 2025-01 -Crop "60,60,4400,6590"
     ```
   - 作風が伝わるよう、色や構図は原画に忠実に保ちます
3. スクリプトが表示した `width` / `height` を使い、`_data/works.yml` に1件追記します
4. 下記の「ローカルでの確認」を行います
5. 問題なければ commit して push します

### `_data/works.yml` の項目

```yaml
- id: 2024-03              # 一意。YYYY-NN。ファイル名と一致させる
  year: 2024               # 制作年
  tools: 透明水彩・ペン      # 使用ツール
  image: /assets/images/works/2024-03.jpg
  width: 1600              # 本画像の実寸(スクリプトの出力を貼る)
  height: 1108
  alt: 画像の内容を説明する文(必須)
  # title: 作品タイトル     # 任意。書いた場合だけ拡大表示に出ます
```

一覧は `id` の新しい順(降順)に表示されます。

## ローカルでの確認(必須)

**push する前に、必ずローカルで表示を確認します。** 公開サイトで確認する運用はしません。

### なぜ WSL を使うのか

この PC では、Windows の「スマートアプリコントロール」が、署名のない Ruby の拡張ファイルの読み込みをブロックします。
そのため Windows 版の Ruby では `bundle install` が失敗します(エラー 4551)。
**Jekyll は WSL2 の Ubuntu 上で動かします。** セキュリティ設定は変えません。

### 初回セットアップ(済み)

この PC では完了しています。別の PC で再現するときの手順です。

1. 管理者権限の PowerShell で、WSL と Ubuntu を入れます(再起動が必要な場合があります)
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```
2. Ubuntu に Ruby とビルドツールを入れます
   ```powershell
   wsl -u root -- apt-get update
   wsl -u root -- apt-get install -y ruby-full build-essential zlib1g-dev git
   ```
3. プロジェクトのフォルダで、gem を入れます
   ```powershell
   wsl bash _tools/jekyll.sh install
   ```

Ubuntu 側の Ruby は 3.2 系、Jekyll は GitHub Pages と同じ 3.10 系です。
Windows にインストールした Ruby(`C:\Ruby33-x64`)は使いません。

### 毎回の確認

プロジェクトのフォルダで、次を実行します。

```powershell
wsl bash _tools/jekyll.sh serve
```

ブラウザで http://localhost:4000 を開き、次を確認します。止めるときは、ターミナルで `Ctrl+C` を押します。

- ビルドがエラーなく完了する
- 作品の一覧と、クリックでの拡大表示が正しく動く
- スマートフォン幅(ブラウザの開発者ツールで確認)でも崩れない

ビルドだけ確認するなら `wsl bash _tools/jekyll.sh build` です(出力は `_site/`。git には入りません)。

## 公開

確認が済んだら、変更を commit して `main` に push します。数分後に https://sii-nph.github.io/ へ反映されます。
ブラウザで古い表示が残る場合は `Ctrl+F5` で再読み込みしてください。

ビルド状況は次のコマンドでも確認できます。

```powershell
gh api repos/sii-nph/sii-nph.github.io/pages/builds/latest
```

## 著作権

このサイトに掲載している画像・作品の著作権は sii-nph に帰属します。
無断での転載・複製・加工・再配布・二次利用を禁止します。
