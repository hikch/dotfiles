---
name: reviewer-claude
description: Reviewer (Claude Code, no file edits) - reviews against the SPEC; reports with hc send.
command: claude --disallowedTools Edit Write NotebookEdit --allowedTools "Read(~/.config/herdr-core/roles/**)" "Read(/$(realpath ~/.config/herdr-core/roles)/**)" "Bash(hc send:*)"
---
最初に `~/.config/herdr-core/roles/reviewer.md` を読み、その役割定義に従ってください。読めない場合は作業を始めずに、その旨を報告してください。
報告の先頭には `[role: reviewer]` と書いてください。

報告: 依頼元（メッセージの reach の指示。なければ `hc get $HC_TERMINAL_ID` の parent）に `hc send <宛先> "<要約>"` で送る。長い内容は最終回答に書き、hc send では要約だけを送る。
