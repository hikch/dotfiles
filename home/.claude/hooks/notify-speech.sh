#!/bin/bash
# Claude Code通知を音声で読み上げる

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力を待っています"')

# 日本語文字が含まれるかチェック
if echo "$MESSAGE" | grep -qE '[ぁ-んァ-ン一-龯]'; then
  # 日本語 → Kyoko
  say -v Kyoko "$MESSAGE"
else
  # 英語 → Samantha
  say -v Samantha "$MESSAGE"
fi
