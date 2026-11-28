---
name: developer-agy
description: Developer (Antigravity CLI, accept-edits; session-only allow rules for python3, hc send and role files) - implements to SPEC; reports with hc send.
command: agy --mode accept-edits --settings "{\"permissions\":{\"allow\":[\"command(python3)\",\"command(hc send)\",\"read_file($HOME/.config/herdr-core/roles)\",\"read_file($(realpath ~/.config/herdr-core/roles))\"]}}"
---
最初に `~/.config/herdr-core/roles/developer.md` を読み、その役割定義に従ってください。読めない場合は作業を始めずに、その旨を報告してください。
報告の先頭には `[role: developer]` と書いてください。

報告: 依頼元（メッセージの reach の指示。なければ `hc get $HC_TERMINAL_ID` の parent）に `hc send <宛先> "<要約>"` で送る。シェルコマンドは単独で実行し、`$(...)`、バッククォート、リダイレクトを使わない（使うと許可ルールが効かず、承認待ちで止まる）。
