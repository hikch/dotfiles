#!/bin/bash
# Claude Code通知を音声で読み上げる

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力を待っています"')

# 日本語ボイスで読み上げ
say -v Kyoko "$MESSAGE"
