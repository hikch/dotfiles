# Claude Code Orchestra

**Multi-Agent Orchestration Framework**

Claude Code integrates Codex CLI (deep reasoning) and Gemini CLI (large-scale research), leveraging each agent's strengths to accelerate development.

---

## Why This Exists

| Agent | Strength | Use For |
|-------|----------|---------|
| **Claude Code** | Orchestration, user interaction | Overall coordination, task management |
| **Codex CLI** | Deep reasoning, design decisions, debugging | Design consultation, error analysis, trade-off evaluation |
| **Gemini CLI** | 1M tokens, multimodal, web search | Full codebase analysis, library research, PDF/video processing |

**IMPORTANT**: Tasks difficult for a single agent can be solved through 3-agent collaboration.

---

## Context Management (CRITICAL)

Claude Code context is **200k tokens**, but effectively **70-100k** due to tool definitions.

**YOU MUST** call Codex/Gemini via subagent (for outputs >10 lines).

| Output Size | Method | Reason |
|-------------|--------|--------|
| 1-2 sentences | Direct call OK | No overhead needed |
| 10+ lines | **Via subagent** | Protect main context |
| Analysis reports | Subagent → save to file | Persist details in `.claude/docs/` |

```
# MUST: Via subagent (large output)
Task(subagent_type="general-purpose", prompt="Consult Codex on design, return summary")

# OK: Direct call (small output only)
Bash("codex exec ... 'answer in 1 sentence'")
```

---

## Quick Reference

### When to Use Codex

- Design decisions ("How to implement?", "Which pattern?")
- Debugging ("Why doesn't it work?", "What's the error cause?")
- Comparisons ("A or B?")

→ Details: `.claude/rules/codex-delegation.md`

### When to Use Gemini

- Research ("Look up", "What's the latest?")
- Large-scale analysis ("Understand the entire codebase")
- Multimodal ("Check this PDF/video")

→ Details: `.claude/rules/gemini-delegation.md`

---

## Workflow

```
/startproject <feature-name>
```

1. Gemini analyzes repository (via subagent)
2. Claude gathers requirements, creates plan
3. Codex reviews plan (via subagent)
4. Claude creates task list
5. **Post-implementation review in separate session** (recommended)

→ Details: `/startproject`, `/plan`, `/tdd` skills

---

## Orchestra Documentation

| Location | Content |
|----------|---------|
| `.claude/rules/` | Coding, security, language rules |
| `.claude/docs/DESIGN.md` | Design decision records |
| `.claude/docs/research/` | Gemini research results |
| `.claude/logs/cli-tools.jsonl` | Codex/Gemini I/O logs |

---

## Language Protocol

- **Thinking & Code**: English
- **User interaction**: Japanese

---
---

# Repository Guidelines (dotfiles)

Guidelines for AI coding assistants working with this dotfiles repository.

> **Note**: See [README.md](README.md) for detailed commands and configuration.

## Repository Overview

A dotfiles repository managing macOS development environment configuration. Hybrid approach using symlink deployment and Devbox/Homebrew package management.

## Project Structure

```
~/dotfiles/
  Makefile              # Root orchestrator (delegates to home/)
  .Brewfile             # Homebrew packages (GUI apps, CLI tools)
  hosts/                # Host-specific Brewfiles
  .claude/              # Project-level AI settings (not deployed)
  .codex/               # Codex CLI settings
  .gemini/              # Project-level Gemini settings
  home/                 # Files deployed to $HOME
    Makefile            # Deployment targets
    CANDIDATES          # Deployment whitelist
    EXCLUSIONS          # Excluded files
    PARTIAL_LINKS       # Partial link targets
    .claude/            # → ~/.claude/ (global AI settings)
    .gemini/            # → ~/.gemini/ (global Gemini settings)
    .config/            # Partial links (fish, git, gh)
    .local/             # Partial links (devbox)
```

## Available Development Environment

Global packages managed via Devbox:
- **Config file**: `~/.local/share/devbox/global/default/devbox.json`
- **Check command**: `devbox global list`

**Key tools**: nodejs, uv, gh, fish, fzf, ripgrep, jq, tree, tmux, pandoc, ffmpeg, claude-code, gemini-cli

## AI Tools Configuration

Project-level and global settings are separated:

| Type | Location | Purpose |
|------|----------|---------|
| **Project settings** | `.claude/`, `.codex/`, `.gemini/` | This repository only |
| **Global settings** | `home/.claude/` → `~/.claude/` | All repositories |

## Coding Style & Naming Conventions

- **Shell**: Prefer POSIX `sh`, guard with `set -eu`
- **Makefile**: Tabs for recipes, descriptive target names (e.g., `brew/upgrade`)
- **Brewfiles**: Name as `hosts/<hostname>.Brewfile`
- **Paths**: Repository-relative paths, symlink targets under `home/`

## Commit & Pull Request Guidelines

- **Commits**: Imperative, concise, scoped (e.g., `brew: add jq`, `deploy: skip .config`)
- **Conventional Commits**: `docs:`, `feat:`, `fix:` prefixes recommended
- **PRs**: Include purpose, change summary, affected hosts, manual steps

## Security Tips

- Never commit secrets (exclude via `home/EXCLUSIONS`)
- `~/.config` is opt-in (explicitly manage via `home/PARTIAL_LINKS`)
- Package policy: CLI→Devbox, GUI→Homebrew Cask, daemons→`brew services`

## Notes

- Deployment files live in `home/`, not repository root
- `.config` uses PARTIAL_LINKS for selective management
- Project AI settings (`.claude/`) separate from global (`home/.claude/`)
- Fish shell is primary shell (Fisher plugin management)
