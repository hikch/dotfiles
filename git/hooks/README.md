# Global Git Hooks

グローバルGitフック管理システム。全てのGitリポジトリでセキュリティチェックを自動実行します。

## 概要

このディレクトリは、Git の `init.templateDir` 機能を使用してグローバルフックを管理します。新規リポジトリおよび既存リポジトリに自動的にフックを展開し、プロジェクト固有のフックシステムと共存します。

### なぜ init.templateDir なのか？

- **core.hooksPath の問題**: Husky などのツールがローカル設定でグローバル設定を上書きしてしまう
- **init.templateDir の利点**:
  - 新規リポジトリに自動適用
  - 既存リポジトリも更新スクリプトで一括適用可能
  - プロジェクト固有のフックシステム（Husky, pre-commit framework）と競合しない

## ディレクトリ構造

```
git/
├── hooks/
│   ├── pre-commit          # スマートラッパーフック（実体）
│   └── README.md           # このファイル
└── template/
    └── hooks/
        └── pre-commit      # テンプレート用シンボリックリンク
```

## スマートラッパーフックの動作

`pre-commit` フックは以下の順序で動作します：

### Phase 1: Gitleaks Secret Detection（必須セキュリティチェック）

1. **gitleaks 実行**: ステージされた変更に対してシークレット検出を実行
2. **スキップ条件**: pre-commit framework で gitleaks が設定済みの場合は重複実行を回避
3. **検出時**: シークレット検出時はコミットをブロック

### Phase 2: Project Hook Delegation（優先順位順）

プロジェクト固有のフックシステムを検出し、適切に委譲します：

**優先度1: pre-commit framework**
- 検出: `.pre-commit-config.yaml` の存在
- 動作: `pre-commit run` を実行
- 用途: Python エコシステムで広く使用される標準的なフック管理

**優先度2: Husky**
- 検出: `.husky/pre-commit` の存在
- 動作: Husky の pre-commit スクリプトを実行
- 用途: Node.js プロジェクトで広く使用される

**優先度3: ローカル手動フック**
- 検出: `.git/hooks.local/pre-commit` の存在
- 動作: ローカルフックを実行
- 用途: レガシーパターン、手動管理されたフック

**優先度4: プロジェクトスクリプト**
- 検出: `scripts/pre-commit` の存在（実行可能）
- 動作: プロジェクトのカスタムスクリプトを実行
- 用途: 独自のフック管理パターン

## セットアップ

### 初回セットアップ

```bash
# 1. Git テンプレートディレクトリを設定
git config --global init.templateDir ~/.dotfiles/git/template

# 2. 既存リポジトリに適用（オプション）
~/dotfiles/bin/git-hooks-update
```

### Makefile 経由での実行

```bash
# 全セットアップ（gitconfig更新 + 既存リポジトリ更新）
make git-hooks-setup

# 既存リポジトリのみ更新
make git-hooks-update
```

## 新規リポジトリでの自動適用

`init.templateDir` が設定されると、以下の操作で自動的にフックが適用されます：

```bash
# 新規リポジトリ作成
git init my-project

# リモートリポジトリのクローン
git clone https://github.com/user/repo.git
```

どちらの場合も、`.git/hooks/pre-commit` が自動的に作成されます。

## 既存リポジトリへの適用

### 手動適用（単一リポジトリ）

```bash
cd /path/to/existing/repo
git init
```

`git init` を既存リポジトリで実行すると、テンプレートが再適用されます（既存ファイルは上書きされません）。

### 一括適用（全リポジトリ）

```bash
# ~/dev/ 配下の全リポジトリを更新
~/dotfiles/bin/git-hooks-update ~/dev

# 特定ディレクトリのみ
~/dotfiles/bin/git-hooks-update ~/projects/work ~/projects/personal
```

## プロジェクト固有フックとの共存

### Husky プロジェクトの場合

グローバルフックが自動的に Husky を検出し、`.husky/pre-commit` に委譲します：

```
実行順序:
1. グローバルフック: gitleaks 実行
2. グローバルフック: Husky を検出
3. Husky: .husky/pre-commit を実行
```

### pre-commit framework の場合

`.pre-commit-config.yaml` で gitleaks が設定されている場合、重複実行を回避：

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

```
実行順序:
1. グローバルフック: gitleaks 設定を検出、スキップ
2. グローバルフック: pre-commit framework に委譲
3. pre-commit: gitleaks を含む全フックを実行
```

gitleaks が設定されていない場合：

```
実行順序:
1. グローバルフック: gitleaks 実行
2. グローバルフック: pre-commit framework に委譲
3. pre-commit: 設定された全フックを実行
```

### ローカル手動フックの場合

既存の手動フックは `.git/hooks.local/` に移動すると引き続き実行されます：

```bash
# 既存フックの移動
mkdir -p .git/hooks.local
mv .git/hooks/pre-commit .git/hooks.local/pre-commit
git init  # グローバルフックを適用
```

## フックのカスタマイズ

### プロジェクトでグローバルフックを無効化

特定プロジェクトでグローバルフックをスキップする場合：

```bash
# プロジェクトローカルで無効化
cd /path/to/project
rm .git/hooks/pre-commit

# または空のフックに置き換え
echo '#!/bin/sh' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### gitleaks 設定のカスタマイズ

プロジェクトルートに `.gitleaks.toml` を配置すると、そのプロジェクト専用の設定が適用されます：

```bash
# dotfiles の設定をコピーして編集
cp ~/.dotfiles/.gitleaks.toml ./.gitleaks.toml
git add .gitleaks.toml
```

## トラブルシューティング

### フックが実行されない

```bash
# フックが存在するか確認
ls -la .git/hooks/pre-commit

# 実行権限を確認
ls -l .git/hooks/pre-commit

# 手動で再適用
git init
```

### gitleaks がインストールされていない

```bash
# Devbox 経由でインストール
devbox global add gitleaks@latest

# または Homebrew
brew install gitleaks
```

### pre-commit framework と重複実行される

`.pre-commit-config.yaml` に gitleaks が設定されている場合、自動的にスキップされます。スキップされていない場合は設定を確認してください：

```bash
# gitleaks が設定されているか確認
grep -i gitleaks .pre-commit-config.yaml
```

### Husky が動作しなくなった

グローバルフックは Husky を検出して委譲するため、通常は問題ありません。もし動作しない場合：

```bash
# Husky が正しく設定されているか確認
ls -la .husky/pre-commit

# Husky を再インストール
npm install
npx husky install
```

## セキュリティ注意事項

### シークレット検出の限界

gitleaks は強力なツールですが、全てのシークレットを検出できるわけではありません：

- **誤検知**: 正規表現ベースのため、誤検知が発生する可能性があります
- **検出漏れ**: 独自形式のシークレットは検出できない場合があります
- **暗号化データ**: 既に暗号化されたデータは検出されません

### 多層防御アプローチ

1. **コミット前**: このグローバルフック（gitleaks）
2. **リポジトリレベル**: `.gitignore` でシークレットファイルを除外
3. **環境変数**: `.env` ファイルを使用し、`.env.example` のみコミット
4. **CI/CD**: GitHub Actions などでさらにスキャン
5. **定期スキャン**: `make security-scan` で履歴全体をスキャン

### バイパスの使用

`--no-verify` フラグでフックをバイパスできますが、推奨されません：

```bash
# 緊急時のみ使用（非推奨）
git commit --no-verify -m "emergency fix"
```

バイパスした場合は、後で必ず修正してください：

```bash
# 最後のコミットを修正
git reset --soft HEAD~1
# シークレットを削除
vim file-with-secret.txt
# 再コミット（フック付き）
git add file-with-secret.txt
git commit -m "fix: remove secrets"
```

## 関連ドキュメント

- [gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [pre-commit Framework](https://pre-commit.com/)
- [Husky](https://typicode.github.io/husky/)

## 参考

このシステムは以下のベストプラクティスに基づいています：

- **Defense in Depth**: 多層防御でシークレット漏洩を防止
- **Convention over Configuration**: 標準的なフックシステムを自動検出
- **Non-Breaking**: 既存プロジェクトのワークフローを破壊しない
- **Transparency**: フックの動作を明確にログ出力
