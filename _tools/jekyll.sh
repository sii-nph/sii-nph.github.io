#!/bin/bash
# Jekyll を WSL（Ubuntu）上で実行する。Windows の Ruby は使わない（スマートアプリコントロールでブロックされるため）。
#
# 使い方（リポジトリのルートで、Windows の PowerShell から）:
#   wsl bash _tools/jekyll.sh install   # 初回のみ。bundler と gem を入れる
#   wsl bash _tools/jekyll.sh serve     # ローカル確認（http://localhost:4000）。Ctrl+C で止める
#   wsl bash _tools/jekyll.sh build     # ビルドだけ行う（_site/ に出力）
set -e

# Windows 側の PATH が混ざらないようにし、ユーザー領域に入れた bundler を使えるようにする
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"

cd "$(dirname "$0")/.."

case "${1:-serve}" in
  install)
    gem list -i bundler -v '~> 2.5' >/dev/null 2>&1 || gem install --user-install --no-document bundler -v '~> 2.5'
    # gem は Ubuntu のホームに入れる（Windows 側のフォルダを汚さない）
    bundle config set --global path "$HOME/gems"
    bundle install --jobs 4
    ;;
  serve)
    exec bundle exec jekyll serve --host 0.0.0.0 --port 4000 --force_polling
    ;;
  build)
    exec bundle exec jekyll build
    ;;
  *)
    echo "usage: wsl bash _tools/jekyll.sh [install|serve|build]" >&2
    exit 1
    ;;
esac
