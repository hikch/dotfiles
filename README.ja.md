# dotfiles

> **Note**: これが正本です。英語版: [README.md](README.md)

## インストール

以下を実行：

``` sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/hikch/dotfiles/main/bootstrap.sh)"
```

または

``` sh
git clone git@github.com:hikch/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy
```

これにより、dotfiles内の適切なファイルがホームディレクトリにシンボリックリンクされます。
全ての設定は`~/dotfiles`内で行います。

⚠️ スクリプトを実行する前に、内容を理解していることを確認してください！

### パッケージとアプリケーションのインストール

パッケージとアプリケーションをインストールするには：

``` sh
make init
```

これにより、Devbox、グローバルパッケージ設定、Homebrewアプリケーション、Fishシェルのセットアップ、macOSデフォルト設定が適用されます。

## 使用方法

### コアコマンド

``` sh
$ cd ~/dotfiles
$ make help
deploy                         Deploy dotfiles.
devbox-global-install          devbox global install
doctor                         Run comprehensive environment health checks
fish                           Install fish plug-ins & Add direnv hook
git-hooks-setup                Setup global git hooks (configure + update existing repos)
git-hooks-update               Update existing repositories with global hooks
homebrew                       Install homebrew packages
init                           Initialize.
iterm2-profiles                Deploy iTerm2 Dynamic Profiles
mac-defaults                   Setup macos settings
migrate-add-partial-link       [Plan B] Add path to PARTIAL_LINKS (real dir → symlink)
migrate-remove-partial-link    [Plan C] Remove path from PARTIAL_LINKS (symlink → real dir)
migrate-top-symlink-to-real    [Plan A] Migrate TOP from symlink to real directory (one-time rescue)
pmset-settings                 Setup power management settings (model-specific)
security-install               Install security tools and hooks
security-protect               Scan staged changes before commit
security-scan                  Run full gitleaks scan of repository history
status                         Quick environment status check
validate-partial-links         Validate PARTIAL_LINKS configuration before deploy
vim                            Install vim plug-ins
```

**注：** `make help`はターゲット名に`/`を含むターゲット（`brew/*`、`packages/*`、`doctor/*`、`deploy/*`など）は表示しません。これらのターゲットの詳細はMakefileを直接参照してください。

### ドライラン デプロイ（安全なテスト）

一時的なHOMEを使用して、実際のホームに触れることなく`make deploy`が何をシンボリックリンクするかを素早く検証：

``` sh
HOME=$(mktemp -d) make deploy
```

これは分離されたサンドボックスディレクトリでデプロイをシミュレートするため、安全に出力を確認できます。

### Homebrew Bundle管理

ホスト固有の設定を持つ新しいBrewfile管理：

``` sh
# パッケージ操作
make brew/setup                # .Brewfile（とホストインクルード）からパッケージをインストール/アップグレード
make brew/check                # 全てが満たされているか確認（詳細付き）
make brew/cleanup              # Brewfileにない削除可能なパッケージを表示
make brew/cleanup-force        # Brewfileにないパッケージを削除
make brew/upgrade              # 全てをアップグレード（formulae & casks）

# パッケージの追加
make brew/cask-add NAME=app    # 共通の.BrewfileにGUIアプリを追加
make brew/host-cask-add NAME=app # 現在のホストのBrewfileにGUIアプリを追加

# ユーティリティ
make brew/dump-actual          # 現在の状態をBrewfile.actualにスナップショット
```

## 設定

### `.config` と `.local` の管理ポリシー

このリポジトリは設定ファイル管理に厳格な**ホワイトリストアプローチ**を採用しています：

**追跡されるもの：**
- **手動で編集した宣言的な設定**ファイルのみ
- **再現可能**で**マシン間で意味のある**ファイル
- **シークレット、状態、自動生成コンテンツを含まない**ファイル

**判断ルール**（全てYESの場合のみ追跡）：
1. 手動でこのファイルを編集したか？
2. 他のマシンでも意味があるか？
3. シークレット、状態、自動生成ファイルではないか？

**`.config` ディレクトリ：**
- デフォルト：全て除外
- 明示的に含む：`fish/config.fish`、`fish/conf.d/*.fish`、`git/config`、`direnv/direnv.toml`など
- 明示的に除外：`fish_variables`（作業状態）、補完、自動生成関数

**`.local` ディレクトリ：**
- デフォルト：全て除外
- 例外：自作スクリプト（例：`.local/bin/`）
- Devbox：現在`.local/share/devbox/global/default/`を`PARTIAL_LINKS`で管理

完全なホワイトリスト設定は`.config/.gitignore`を参照してください。

#### PARTIAL_LINKS管理

このリポジトリはPARTIAL_LINKS管理のための3つのマイグレーションツールを提供します：

##### Plan A：一度きりのレスキューマイグレーション（TOPシンボリック → 実ディレクトリ）

**使用タイミング：** レガシーな全ディレクトリシンボリック構造からの移行（一度のみ）

```bash
make migrate-top-symlink-to-real
```

**動作内容：**
1. 親ディレクトリ（`.config`、`.local`）が現在シンボリックリンクか検出
2. PARTIAL_LINKS以外の全コンテンツを`/tmp/dotfiles-migration-*/`にバックアップ
3. シンボリックリンクを実ディレクトリに変換
4. 管理外ファイルをホームディレクトリに復元
5. PARTIAL_LINKS以外のアイテムをリポジトリからクリーンアップ

**注：** このコマンド実行後は`make deploy`を実行してPARTIAL_LINKSのシンボリックリンクを作成する必要があります。

**例：**
```
変更前：
  ~/.config -> ~/dotfiles/.config （全体がシンボリックリンク）

変更後：
  ~/.config/ （実ディレクトリ）
    ├── fish -> ~/dotfiles/.config/fish （シンボリックリンク、管理対象）
    ├── git -> ~/dotfiles/.config/git （シンボリックリンク、管理対象）
    ├── gcloud/ （実ディレクトリ、ローカル状態）
    └── gh/ （実ディレクトリ、ローカル状態）

  ~/dotfiles/.config/ （リポジトリ）
    ├── fish/ （追跡対象）
    ├── git/ （追跡対象）
    └── .gitignore （gcloud、ghはリポジトリから削除）
```

**安全性：** 破壊的（バックアップ必須）、初回マイグレーション時のみ実行。

---

##### Plan B：PARTIAL_LINKSへの追加（実ディレクトリ → シンボリックリンク）

**使用タイミング：** `PARTIAL_LINKS`ファイルに新しいパスを追加した後

```bash
# 1. PARTIAL_LINKSを編集して.config/uvを追加
# 2. マイグレーション実行
make migrate-add-partial-link path=.config/uv
```

**動作内容：**
1. 既存の`~/.config/uv`を`$(MIGRATION_BACKUP_DIR)/add`（デフォルト：`/tmp/dotfiles-migration-.../add`）にバックアップ
2. 実ディレクトリ/ファイルを削除
3. シンボリックリンク`~/.config/uv -> ~/dotfiles/.config/uv`を作成
4. バックアップ内容の手動レビューを促す

**重要：** ディレクトリの場合は自動コピーされません。ファイルの場合は自動的にリポジトリにコピーされます。バックアップをレビューし、ディレクトリの場合は必要な設定を手動でリポジトリにコピーしてください。

---

##### Plan C：PARTIAL_LINKSからの削除（シンボリックリンク → 実ディレクトリ）

**使用タイミング：** `PARTIAL_LINKS`ファイルからパスを削除した後

```bash
# 1. PARTIAL_LINKSを編集して.config/gitを削除
# 2. マイグレーション実行
make migrate-remove-partial-link path=.config/git
```

**動作内容：**
1. リポジトリ内容を`$(MIGRATION_BACKUP_DIR)/remove`（デフォルト：`/tmp/dotfiles-migration-.../remove`）にバックアップ
2. シンボリックリンクを削除
3. 実ディレクトリを作成しリポジトリから内容をコピー
4. リポジトリ内容を保持（手動クリーンアップが必要）

**重要：** リポジトリ内容は保持されます。不要な場合は`.gitignore`に追加するか手動で削除してください。

### パッケージ管理戦略

このリポジトリは最適なパッケージ管理のためのハイブリッドアプローチを使用します：

- **Devbox**: CLIツールと開発ユーティリティ（Node.js、jq、ripgrep、masなど）
- **Homebrew Cask**: GUIアプリケーションのみ（ブラウザ、エディタ、生産性アプリ）
- **ホスト固有設定**: `hosts/`ディレクトリ経由でマシンごとに異なるパッケージ

#### サービス管理ポリシー

バックグラウンドサービスはスコープに基づいて管理されます：

- **`brew services`**: システム全体、常時起動のデーモン（tailscaled、syncthing、共有データベース、GUIエージェント）
  - macOS LaunchAgents/Daemonsと統合
  - 再起動とユーザーセッション間で永続化
- **`devbox services`**: プロジェクトスコープ、バージョン固定の依存関係（開発データベース、ローカルサービス）
  - プロジェクト環境と共に開始/停止
  - 異なるプロジェクト間での再現性を保証

**経験則**：システム全体 → `brew services`、プロジェクト固有 → `devbox services`

#### Homebrewホスト設定

`.Brewfile`は自動ホスト固有インクルードをサポート：

```
dotfiles/
  .Brewfile                    # 共通GUIアプリケーション
  hosts/
    iMac-2020.Brewfile        # iMac固有パッケージ（例：サーバーツール）
    MacBookAir2025.Brewfile   # MacBookAir固有パッケージ（例：開発ツール）
```

ホストファイルは`hostname -s`を使用して自動検出され、`brew bundle`操作時にインクルードされます。

### デプロイ設定

デプロイ動作は外部設定ファイルで制御されます：

- **`CANDIDATES`** - `$HOME`にシンボリックリンクされるファイルとディレクトリ（ホワイトリスト）
- **`EXCLUSIONS`** - デプロイから除外するファイルとディレクトリ
- **`PARTIAL_LINKS`** - 個別にシンボリックリンクするネストパス（親ディレクトリは自動除外）

デプロイ内容を変更するには：
1. `CANDIDATES`を編集して新しいデプロイターゲットを追加
2. `EXCLUSIONS`を編集してファイル/ディレクトリを除外
3. `PARTIAL_LINKS`を編集して選択的なネストパスシンボリックリンクを追加
4. `make deploy`を実行して変更を適用

### Syncthing使用方法

Syncthingインストールはホストによって異なります：

**共通（全マシン）：**
- `cask "syncthing"`経由のGUIアプリケーション

**ホスト固有（iMacのみ）：**
- サーバー機能用に`brew "syncthing"`経由のCLIバージョン

**使用方法：**
``` sh
# デスクトップ使用（全マシン）
open /Applications/Syncthing.app

# サーバー使用（iMacのみ）
brew services start syncthing
brew services stop syncthing
```

## ツールセット

- [devbox](https://www.jetify.com/devbox) - 開発ツールのプライマリパッケージマネージャー
- [direnv](https://github.com/direnv/direnv)
- [fish](https://fishshell.com) - Fisherプラグイン管理を備えたシェル
- [homebrew](https://brew.sh) - macOSアプリケーションといくつかのCLIツール
- [jq](https://stedolan.github.io/jq/)
- [macvim](https://macvim-dev.github.io/macvim/)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [tmux](https://github.com/tmux/tmux)
その他多数...

## TODO

- [ ] リモートホスト追加時のSSH設定作成スクリプト
- [ ] Makefileをモジュールファイルに分割（make/deploy.mk、make/homebrew.mk、make/devtools.mk、make/macos.mk）
- [x] defaultsコマンドを使用してMacOS設定を自動化
- [x] Devboxを使用したパッケージ管理に切り替え
- [x] 互換性向上のためNixからDevboxに移行

## 謝辞

- AIコーディング設定は [claude-code-orchestra](https://github.com/Sunwood-ai-labs/claude-code-orchestra) をベースにしています（MITライセンス）
