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
  home/                 # Files deployed to $HOME
    Makefile            # Deployment targets
    CANDIDATES          # Deployment whitelist
    EXCLUSIONS          # Excluded files
    PARTIAL_LINKS       # Partial link targets
    .claude/            # → ~/.claude/ (global AI settings)
    .config/            # Partial links (fish, git, gh, herdr)
    .local/             # Partial links (devbox)
```

## Available Development Environment

Global packages managed via Devbox:
- **Config file**: `~/.local/share/devbox/global/default/devbox.json`
- **Check command**: `devbox global list`

**Key tools**: nodejs, uv, gh, fish, fzf, ripgrep, jq, tree, tmux, pandoc, ffmpeg, claude-code, antigravity-cli (agy), herdr

## AI Tools Configuration

Project-level and global settings are separated:

| Type | Location | Purpose |
|------|----------|---------|
| **Project settings** | `.claude/` | This repository only |
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
