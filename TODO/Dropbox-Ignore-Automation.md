# Dropboxでの`.git`除外と自動化メモ

目的: Dropbox配下のあらゆるリポジトリで`.git`や一時生成物をDropbox同期対象から除外して衝突・負荷を防ぐ。

## 現状の手動対応
- 方式: macOSの拡張属性 `com.dropbox.ignored=1` を対象に付与する。
- 例（Dropbox配下すべてに適用）:
  ```bash
  # Dropboxルート（パスは環境に合わせて変更）
  DROPBOX_ROOT="$HOME/Library/CloudStorage/Dropbox"

  # .git を除外
  find "$DROPBOX_ROOT" -type d -name .git -exec xattr -w com.dropbox.ignored 1 {} \;

  # 主要なキャッシュ/生成物も除外（必要に応じて追加）
  for n in .pytest_cache .tox __pycache__ .venv node_modules .serena .vite dist logs tmp db_data; do
    find "$DROPBOX_ROOT" -type d -name "$n" -exec xattr -w com.dropbox.ignored 1 {} \;
  done

  # .DS_Store も除外（任意）
  find "$DROPBOX_ROOT" -name .DS_Store -exec xattr -w com.dropbox.ignored 1 {} \;
  ```
- 解除: `xattr -d com.dropbox.ignored <path>`

## 将来の自動化案（TODO）
- Option A: 定期実行（推奨・簡易）
  - `launchd` のエージェントで1日1回上記コマンドを実行。
  - 手順イメージ:
    1. `~/Scripts/dropbox-ignore-scan.sh` を作成（上記のfindコマンド群を内包）。
    2. `~/Library/LaunchAgents/com.user.dropbox-ignore.plist` を配置（`ProgramArguments`でスクリプトを指定、`StartInterval`で間隔指定）。
    3. `launchctl load -w ~/Library/LaunchAgents/com.user.dropbox-ignore.plist`

- Option B: ファイル監視（高頻度・高度）
  - `fswatch` 等でDropbox配下を監視し、新規に作られた`.git`やキャッシュを検知して即時 `xattr` 付与。
  - 利点: 即時反映。欠点: 常駐コストとセットアップの複雑さ。

## 注意事項
- Dropboxの仕様変更で`com.dropbox.ignored`の挙動が変わる可能性あり。動作不審時はGUIの「Ignore this item」で確認。
- Windows/Linuxは別手段が必要（この方法はmacOS専用）。
- 秘密情報はそもそもDropboxに置かない or 暗号化を推奨。

## 参考リスト（除外候補）
- ディレクトリ: `.git`, `.pytest_cache`, `.tox`, `__pycache__`, `.venv`, `node_modules`, `.serena`, `.vite`, `dist`, `logs`, `tmp`, `db_data`
- ファイル: `.DS_Store`

