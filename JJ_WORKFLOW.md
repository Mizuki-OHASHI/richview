# jj (Jujutsu) 運用ガイド

本プロジェクトでは Git の代わりに **jj (Jujutsu)** でバージョン管理を行う。
jj は Git リポジトリと colocated（共存）しており、必要に応じて Git 操作も可能。

## 環境情報

- jj バージョン: 0.39.0
- バックエンド: Git (colocated)
- インストール: `brew install jj`

## 初期セットアップ

```bash
# ユーザー情報の設定（未設定の場合）
jj config set --user user.name "Your Name"
jj config set --user user.email "your@email.com"

# エディタの設定（デフォルト: vim）
jj config set --user ui.editor "vim"
```

## 基本概念

### Git との主な違い

| 概念 | Git | jj |
|------|-----|-----|
| 作業中の変更 | staging area (index) | working copy が自動的に commit |
| コミット識別 | SHA ハッシュ | change ID（短い英字 ID） |
| ブランチ | branch | bookmark |
| 履歴変更 | rebase -i | `jj rebase`, `jj squash` |
| stash | `git stash` | 不要（新しい change を作るだけ） |

### jj の動作モデル

- **ファイルを保存した時点で自動的に working copy の change に記録される**（`git add` 不要）
- change は immutable なスナップショット。編集すると新しいバージョンが作られる
- `@` は常に現在の working copy を指す

## 日常のワークフロー

### 状態確認

```bash
# 現在の状態を確認（git status 相当）
jj status
jj st           # 短縮形

# 変更履歴を見る（git log 相当）
jj log

# 差分を見る
jj diff                  # working copy の差分
jj diff -r <change_id>   # 特定の change の差分
```

### change の作成と管理

```bash
# 現在の working copy を確定して新しい change を開始
jj new

# 説明（コミットメッセージ）をつける
jj describe -m "変更の説明"
jj desc -m "変更の説明"   # 短縮形

# describe してから new する（一連の流れ）
jj new -m "次の change の説明"

# 空の change を特定の change の上に作る
jj new <change_id>
```

### 変更の統合・整理

```bash
# 現在の change を親にまとめる（squash）
jj squash

# 特定の change を別の change にまとめる
jj squash --from <source> --into <target>

# change の順序を変える
jj rebase -r <change_id> -d <destination>

# change とその子孫をまとめて移動
jj rebase -s <source> -d <destination>

# change を分割する
jj split
```

### 変更の取り消し・復元

```bash
# change の内容を空にする（change 自体は残る）
jj restore

# 特定ファイルだけ元に戻す
jj restore <file_path>

# change を破棄する
jj abandon <change_id>

# 操作自体を取り消す（undo）
jj undo
```

## Bookmark（ブランチ）管理

```bash
# bookmark の一覧
jj bookmark list
jj bookmark list --all   # リモート含む

# bookmark を作成（現在の change に）
jj bookmark create <name>

# bookmark を作成（特定の change に）
jj bookmark create <name> -r <change_id>

# bookmark を移動
jj bookmark move <name> --to <change_id>

# bookmark を削除
jj bookmark delete <name>
```

## リモート操作（Git 連携）

```bash
# リモートの追加
jj git remote add origin <url>

# リモートから取得
jj git fetch

# リモートにプッシュ
jj bookmark move main --to @   # main bookmark を現在の change に移動
jj git push

# 特定の bookmark だけプッシュ
jj git push --bookmark <name>
```

## コンフリクト解決

jj ではコンフリクトが発生してもそのまま記録される（Git のように作業がブロックされない）。

```bash
# コンフリクトの確認
jj log    # コンフリクトがある change には印がつく

# コンフリクトを解決
# 1. ファイルを直接編集してコンフリクトマーカーを解消する
# 2. jj が自動的に解決を検知する（resolve コマンド不要）

# マージツールで解決
jj resolve <file_path>
```

## 便利なコマンド

```bash
# change の内容を一覧表示
jj show <change_id>

# ファイルの変更履歴
jj log <file_path>

# 操作履歴（jj 自体の操作ログ）
jj operation log
jj op log          # 短縮形

# 過去の操作時点に戻す
jj operation restore <operation_id>

# Git コマンドを直接実行（colocated なので可能）
jj git import    # Git 側の変更を jj に取り込む
jj git export    # jj の bookmark を Git branch に反映
```

## よくあるシナリオ

### 機能開発の流れ

```bash
jj new -m "feat: ユーザー認証機能の追加"
# ... コードを書く ...
jj diff                          # 差分確認
jj desc -m "feat: ユーザー認証機能の追加（JWT対応）"  # 説明を修正
jj new                           # 次の作業へ
```

### 作業を一時中断して別の修正をする

```bash
# stash は不要。新しい change を作って作業するだけ
jj new <中断したい change の親>
# ... 緊急修正 ...
jj new <元の change>             # 元の作業に戻る
```

### 複数の change をまとめてからプッシュ

```bash
jj squash --from <change_a> --into <change_b>
jj bookmark move main --to <change_b>
jj git push
```

## 注意事項

- jj は working copy の変更を自動追跡するため、**大きなバイナリファイルの配置に注意**
- `.gitignore` は jj でも有効（colocated モードのため）
- `jj undo` で直前の操作を安全に取り消せるので、積極的に試してよい
- Git コマンドを直接使った場合は `jj git import` で同期すること
