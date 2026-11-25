---
name: antigravity-system
description: |
  PROACTIVELY consult Antigravity CLI for research, large codebase comprehension,
  and multimodal data processing. Antigravity excels at: massive context windows (1M tokens),
  Google Search grounding, video/audio/PDF analysis, and repository-wide understanding.
  Use for pre-implementation research, documentation analysis, and multimodal tasks.
  Explicit triggers: "research", "investigate", "analyze video/audio/PDF", "understand codebase".
metadata:
  short-description: Claude Code ↔ Antigravity CLI collaboration (research & multimodal)
---

# Antigravity System — Research & Multimodal Specialist

**Antigravity CLI (agy) is your research specialist with 1M token context.**

> **詳細ルール**: `.claude/rules/antigravity-delegation.md`

## Context Management (CRITICAL)

**サブエージェント経由を推奨。** Antigravity出力は大きくなりがちなため。

| 状況 | 方法 |
|------|------|
| コードベース分析 | サブエージェント経由（推奨） |
| ライブラリ調査 | サブエージェント経由（推奨） |
| マルチモーダル | サブエージェント経由（推奨） |
| 短い質問 (1-2文回答) | 直接呼び出しOK |

## Antigravity vs Codex

| Task | Antigravity | Codex |
|------|--------|-------|
| **リポジトリ全体理解** | ✓ | |
| **ライブラリ調査** | ✓ | |
| **マルチモーダル (PDF/動画/音声)** | ✓ | |
| **最新ドキュメント検索** | ✓ | |
| **設計判断** | | ✓ |
| **デバッグ** | | ✓ |
| **コード実装** | | ✓ |

## When to Consult (MUST)

| Situation | Trigger Examples |
|-----------|------------------|
| **Research** | 「調べて」「リサーチ」 / "Research" "Investigate" |
| **Library docs** | 「ライブラリ」「ドキュメント」 / "Library" "Docs" |
| **Codebase analysis** | 「コードベース全体」 / "Entire codebase" |
| **Multimodal** | 「PDF」「動画」「音声」 / "PDF" "Video" "Audio" |

## When NOT to Consult

- Design decisions (use Codex)
- Debugging (use Codex)
- Code implementation (use Codex)
- Simple file operations (do directly)

## How to Consult

### Recommended: Subagent Pattern

**Use Task tool with `subagent_type='general-purpose'` to preserve main context.**

```
Task tool parameters:
- subagent_type: "general-purpose"
- run_in_background: true (optional, for parallel work)
- prompt: |
    Research: {topic}

    agy -p "{research question}" 2>/dev/null

    Save full output to: .claude/docs/research/{topic}.md
    Return CONCISE summary (5-7 bullet points).
```

### Direct Call (Short Questions Only)

For quick questions expecting brief answers:

```bash
agy -p "Brief question" 2>/dev/null
```

### CLI Options Reference

```bash
# Codebase analysis
agy -p "{question}" --add-dir . 2>/dev/null

# Multimodal (PDF/video/audio)
agy -p "{prompt} (file: /path/to/file.pdf)" 2>/dev/null

# JSON output
agy -p "{question}" --output-format json 2>/dev/null
```

### Workflow (Subagent)

1. **Spawn subagent** with Antigravity research prompt
2. **Continue your work** → Subagent runs in parallel
3. **Receive summary** → Subagent returns key findings
4. **Full output saved** → `.claude/docs/research/{topic}.md`

## Language Protocol

1. Ask Antigravity in **English**
2. Receive response in **English**
3. Synthesize and apply findings
4. Report to user in **Japanese**

## Output Location

Save Antigravity research results to:
```
.claude/docs/research/{topic}.md
```

This allows Claude and Codex to reference the research later.

## Task Templates

### Pre-Implementation Research

```bash
agy -p "Research best practices for {feature} in Python 2025.
Include:
- Common patterns and anti-patterns
- Library recommendations (with comparison)
- Performance considerations
- Security concerns
- Code examples" 2>/dev/null
```

### Repository Analysis

```bash
agy -p "Analyze this repository:
1. Architecture overview
2. Key modules and responsibilities
3. Data flow between components
4. Entry points and extension points
5. Existing patterns to follow" --add-dir . 2>/dev/null
```

### Library Research

See: `references/lib-research-task.md`

### Multimodal Analysis

```bash
# Video
agy -p "Analyze video: main concepts, key points, timestamps (file: tutorial.mp4)" 2>/dev/null

# PDF
agy -p "Extract: API specs, examples, constraints (file: api-docs.pdf)" 2>/dev/null

# Audio
agy -p "Transcribe and summarize: decisions, action items (file: meeting.mp3)" 2>/dev/null
```

## Integration with Codex

| Workflow | Steps |
|----------|-------|
| **New feature** | Antigravity research → Codex design review |
| **Library choice** | Antigravity comparison → Codex decision |
| **Bug investigation** | Antigravity codebase search → Codex debug |

## Why Antigravity?

- **1M token context**: Entire repositories at once
- **Google Search**: Latest information and docs
- **Multimodal**: Native PDF/video/audio processing
- **Fast exploration**: Quick overview before deep work
- **Shared context**: Results saved for Claude/Codex
