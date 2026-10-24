# CLAUDE.md

このリポジトリで作業する Claude Code 向けのルールです。人向けの説明は README.md を参照してください。

## プロジェクトの目的

sii-nph が描いたアナログの絵（スキャン／写真）をまとめたポートフォリオサイト。公開URL: https://sii-nph.github.io/

**見る人が一覧で作風を把握できること**が最優先。作品が主役で、UI は控えめにする。
作品は現在10点程度で、今後増える。

## 技術方針

- Jekyll（GitHub Pages 標準）。ブランチ公開（`main` / ルート）で、push すると GitHub 側でビルドされる
- GitHub Pages が対応する機能・プラグインだけを使う
- JavaScript は作品の拡大表示のみ。それ以外に増やさない
- Node 系のビルド（Vite、Astro 等）は入れない
- 外部 CDN、トラッキング、外部フォントを追加しない。必要になったら先にユーザーへ相談する

## ディレクトリ構成

> Jekyll 化は実装済み。ビルドと配信はローカル（WSL）で確認済み。画面表示の目視確認はユーザー待ち。

```
Gemfile                  # github-pages gem など（Gemfile.lock は管理しない）
_config.yml              # Jekyll 設定（exclude で非公開ファイルを指定）
_layouts/default.html    # 共通レイアウト（ヘッダー・フッター・著作権表記）
_data/works.yml          # 作品データ（1作品 = 1エントリ）
_tools/make-images.ps1   # 元画像から本画像とサムネイルを作る（公開されない）
_tools/jekyll.sh         # WSL 上で Jekyll を実行する（install / serve / build）
_inbox/                  # 元画像の置き場（.gitignore 済み・公開されない）
assets/css/style.css     # スタイル（タイル一覧・拡大表示を含む）
assets/js/lightbox.js    # 拡大表示（<dialog> を使用）
assets/images/works/     # 本画像（長辺 1600px）
assets/images/thumbs/    # サムネイル（長辺 640px）
index.html               # works.yml からタイル一覧を生成
```

## 作品データ（`_data/works.yml`）

1作品 = 1エントリ。項目は次のとおり。

| 項目 | 内容 |
|---|---|
| `id` | 一意。`YYYY-NN`（例: `2024-01`）。ファイル名と一致させる |
| `title` | 作品タイトル（**任意**。無ければ表示しない） |
| `year` | 制作年 |
| `tools` | 使用ツール（例: 透明水彩・ペン） |
| `image` | 本画像のパス |
| `thumb` | サムネイルのパス |
| `width` / `height` | サムネイルの実寸（px）。タイルの幅の計算に使う。`make-images.ps1` の出力を貼る |
| `alt` | 画像の説明（**必須**） |

- 一覧は `id` の降順（新しいものが先頭）に表示する。同じ年は `NN` が大きいほど新しい
- タグによる絞り込みなどは将来の拡張。今は実装しない

## 画像の取り扱い

アナログ作品のスキャン／写真を扱うためのルール。

- サイズ: 本画像は長辺 1600px、サムネイルは長辺 640px（一覧は Retina でも粗くならないよう余裕を持たせている）。形式は JPG（品質85）
- 変換は `_tools/make-images.ps1` で行う（`-Source` に元画像、`-Name` に `YYYY-NN`）。縦横比を保ち、切り抜かない
- **作品の色・構図は原画に忠実に保つ。** 作風が伝わらなくなる過度な色補正・トリミングをしない
- **EXIF（特に位置情報）は残さない。** 上のスクリプトは描き直して出力するので残らない
- ファイル名は `YYYY-NN.jpg`（`NN` は同じ年の通し番号）
- `<img>` には `width` / `height` / `alt` と `loading="lazy"` を付ける（作品が増えても軽く保つため）
- 元データ（大判スキャンなど）はリポジトリに入れない。置き場は `_inbox/`（`.gitignore` 済み・公開されない）。Claude はここから本画像とサムネイルを作成し、`assets/images/` に出力する

## デザイン方針

- 絵が主役。余白を十分に取り、装飾は控えめにする
- ライト／ダーク対応は、既存 `style.css` の CSS 変数（`--bg`、`--fg`、`--accent`、`--card`、`--border`）を踏襲する
- スマートフォン表示を優先して確認する

## 公開サイトとしての注意

- 無断転載を禁止する旨（著作権表記）を、フッターなど目に付く場所に維持する
- 個人情報・位置情報・認証情報を載せない
- 連絡先は現状 GitHub のみ。SNS やメールを載せる場合は、ユーザーの指示を受けてから追記する

## 作業ルール

- **commit と push は、ユーザーが明示的に指示したときだけ行う。** push の前に差分を示して確認を取る
- **ローカル確認は必須。** 変更後は `wsl bash _tools/jekyll.sh serve`（または `build`）でビルド成功と配信を確認し、結果を報告してから push の確認に進む。確認できない場合は push を提案せず、理由を伝える
- 表示（見た目・拡大表示の動作）は Claude には確認できない（ブラウザ操作ツールが無い）。**目視の確認はユーザーに依頼し、結果を聞いてから** push の確認に進む
- 応答は日本語。コミットメッセージも日本語でよい
- 環境は Windows / PowerShell。ツールを新しく入れたら、VS Code を完全に終了して起動し直さないと PATH が反映されない

### 環境の状態

- 導入済み: git、gh（`sii-nph` でログイン済み）
- **Jekyll は WSL2 の Ubuntu 24.04 上で動かす**（Ruby 3.2.3、bundler 2.5 系、Jekyll 3.10.0）。作業用ユーザーは `dev`（パスワードなし・sudo なし。root が必要なときは `wsl -u root`）。gem は Ubuntu の `~/gems` にあり、プロジェクトのフォルダには入らない
- **Windows 側の Ruby（`C:\Ruby33-x64`）は使えない。** Windows の「スマートアプリコントロール」（オン）が、署名の無い Ruby の拡張ファイルの読み込みをブロックする（エラー 4551）。PowerShell で直接 `bundle` や `jekyll` を実行しない
  - **スマートアプリコントロールの設定は Claude が変更してはならない**（オフにすると、Windows の再インストールなしにはオンへ戻せない）
- `/etc/wsl.conf` で `appendWindowsPath=false` にしてある（Windows の Ruby が Ubuntu 側で先に見つかるのを防ぐため）
- 未導入: Docker、Node、Python（Node、Python はこのプロジェクトでは不要）

## よく使うコマンド

プロジェクトのルートで実行する（PowerShell から WSL を呼ぶ）。

```powershell
wsl bash _tools/jekyll.sh serve     # ローカル確認（http://localhost:4000）
wsl bash _tools/jekyll.sh build     # ビルドのみ（出力は _site/）
wsl bash _tools/jekyll.sh install   # gem の導入（Gemfile を変えたとき）
gh api repos/sii-nph/sii-nph.github.io/pages/builds/latest   # Pages のビルド状況
```

`serve` は終了しないコマンドなので、Claude が実行するときはバックグラウンドで起動し、確認が済んだら止める。
