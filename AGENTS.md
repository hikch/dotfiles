# Repository Guidelines

This file provides guidance to AI coding assistants (Claude Code, Gemini CLI, etc.) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages macOS development environment configuration using a hybrid approach of traditional symlink deployment and modern package management via Devbox (and previously Nix). The setup manages shell configurations, development tools, applications, and system settings.

### Package Management Strategy
- **Devbox**: Primary package manager for development tools (defined in `.local/share/devbox/global/default/devbox.json`)
- **Homebrew**: macOS applications and some CLI tools (defined in `.Brewfile`)
- **Fish Shell**: Shell configuration with plugin management via Fisher

### Configuration Structure
- **Symlink Deployment**: Core dotfiles are symlinked from this repo to `$HOME` via `make deploy`
- **Partial Links**: Some nested paths like `.local/share/devbox/global/default` are selectively symlinked
- **Excluded Directories**: `.config` is managed separately and not tracked by git (except for specific inclusions)

### Key Components
- `Makefile`: Central orchestrator for all deployment and setup tasks
- `bootstrap.sh`: Remote installation script that clones repo and runs `make deploy`
- `bin/`: Custom vim/macvim wrapper scripts
- `etc/`: System configuration scripts (macOS defaults, terminal themes)

## Available Development Environment

This environment uses Devbox for global package management. To see the current list of available tools and packages, check the Devbox configuration file:

**Devbox Global Configuration:**
- File: `~/.local/share/devbox/global/default/devbox.json`
- Command: `devbox global list` - Shows currently installed packages
- Command: `which <tool>` - Verify if a specific tool is available

**Common Package Categories:**
- Development tools (nodejs, uv, gh)
- System utilities (fish, fzf, ripgrep, jq, tree, tmux)
- Text processing (pandoc, ffmpeg)
- Version control (mercurial)
- AI tools (claude-code, gemini-cli)
- macOS tools (mas)

Always verify tool availability before use, as the package list may change over time.

## Project Structure & Module Organization
- Root: make-driven dotfiles repo for macOS/Linux setup.
- `bin/`: helper scripts added to PATH.
- `etc/`: system setup scripts (e.g., `mac_defaults.sh`).
- `hosts/`: host-specific Homebrew bundles like `$(hostname -s).Brewfile`.
- `.Brewfile`, `.Brewfile.local`: common GUI apps and local overrides.
- `.config/`: not tracked by git by default; opt-in via `.gitignore` edits.
- Control deployment via `CANDIDATES` (whitelist), `EXCLUSIONS` (ignore), and `PARTIAL_LINKS` (nested paths).

## Common Commands

### Initial Setup
```bash
# Clone and deploy dotfiles
git clone git@github.com:hikch/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy

# Full environment setup (run after deploy)
make init
```

### Core Operations
```bash
# Deploy/update symlinks
make deploy

# Install/update all packages and tools
make init

# Individual component management
make homebrew          # Install Homebrew apps
make devbox-install    # Install Devbox package manager
make devbox-global-install  # Install global Devbox packages
make fish             # Setup Fish shell and plugins
make vim              # Install Vim plugins
make mac-defaults     # Apply macOS system settings
```

### Package Management
```bash
# Check available packages in Devbox
devbox global list

# Update Devbox packages
devbox global install

# Update Homebrew packages
brew bundle --file="./.Brewfile"

# Update Fish plugins
fish -c "fisher update"
```

### Utilities
```bash
make help             # Show all available make targets
make nix-clean-backups  # Clean up old Nix installer backups
```

## Development Workflow

1. Modify dotfiles in this repository
2. Run `make deploy` to update symlinks
3. For new packages, add to appropriate package manager:
   - Development tools → `.local/share/devbox/global/default/devbox.json`
   - GUI applications → `.Brewfile`
   - Fish plugins → `.config/fish/fish_plugins`

### AI Tools Configuration

This repository includes configuration for AI development tools:

**Gemini CLI:**
- **Configuration File**: `.config/gemini/README.md`
- **Purpose**: Provides environment context and available package information
- **Deployment**: Standard `.config` subdirectory management

Both configurations reference the Devbox global package list dynamically, ensuring AI tools are aware of available development tools.

## Deployment Configuration

Deployment behavior is controlled by external configuration files:

- **`CANDIDATES`**: Files and directories to be symlinked to `$HOME` (whitelist)
- **`EXCLUSIONS`**: Files and directories to exclude from deployment
- **`PARTIAL_LINKS`**: Nested paths to symlink individually (parent dirs auto-excluded)

### Special Deployment Cases
- **`.config`**: Directory symlinked, but contents selectively managed via `.config/.gitignore`
- **Partial links**: `.local/share/devbox/global/default` is symlinked while `.local` parent is excluded (`PARTIAL_LINKS`)

To modify what gets deployed:
1. Edit `CANDIDATES` to add new deploy targets
2. Edit `EXCLUSIONS` to exclude files/directories
3. Edit `PARTIAL_LINKS` to add selective nested path symlinks
4. Run `make deploy` to apply changes

### PARTIAL_LINKS Migration Mechanism

The Makefile includes automatic migration logic for converting full-directory symlinks to selective PARTIAL_LINKS:

**How it works:**
- When `make deploy` is run, the `deploy/migrate-partial-tops` target executes first
- It detects if any PARTIAL_TOPS directories (e.g., `.config`) are currently full symlinks
- If detected:
  1. Backs up all non-PARTIAL_LINKS content to `/tmp/dotfiles-migration-YYYYMMDD_HHMMSS/`
  2. Removes the old full symlink
  3. Creates a real directory in its place
  4. Restores non-managed files to the new directory
  5. PARTIAL_LINKS symlinks are then created by the main deploy logic

**Example:** Converting `.config` from full symlink to selective links:
```
Before: ~/.config -> ~/dotfiles/.config (full symlink)
After:  ~/.config/ (real directory)
         ├── fish -> ~/dotfiles/.config/fish (PARTIAL_LINK)
         ├── git -> ~/dotfiles/.config/git (PARTIAL_LINK)
         ├── gcloud/ (copied from repo, not a symlink)
         └── coc/ (copied from repo, not a symlink)
```

**Safety features:**
- Migration is idempotent (safe to run multiple times)
- All non-PARTIAL_LINKS files are preserved
- Backup is always created at `/tmp/dotfiles-migration-*/`
- No data loss occurs during conversion

**Note:** This migration is particularly important because:
- Git-untracked files may exist in repository directories (e.g., `.config/gcloud/`)
- These files must be copied to `$HOME` during migration
- Without this mechanism, circular symlink references would occur

## Build, Test, and Development Commands
- `make help`: list available tasks.
- `make deploy`: symlink managed files into `$HOME` (idempotent); fixes `~/.ssh` perms.
- `make init`: first-time setup (Devbox, Homebrew, Fish, macOS defaults).
- `make homebrew` / `make brew/*`: manage packages via Brewfile(s).
- `make vim` / `make fish`: install editor/shell plugins.
- Tip: Dry-run deploy in a sandbox: `HOME=$(mktemp -d) make deploy`.

## Coding Style & Naming Conventions
- Shell: prefer POSIX `sh` for portability; guard scripts with `set -eu` when safe.
- Makefile: use tabs for recipes; keep targets descriptive (e.g., `brew/upgrade`).
- Brewfiles: name host files exactly `hosts/<hostname>.Brewfile`.
- Paths: keep repo‑relative paths; symlink targets live under repo root.

## Testing Guidelines
- Validate changes with `make help`, `make deploy` (sandboxed), and `make brew/check`.
- For host logic, test using a stub: `HOST=$(hostname -s) make brew/setup`.
- Keep deployments reversible; avoid destructive operations in default targets.

## Commit & Pull Request Guidelines
- Commits: imperative, concise, scoped. Examples: `brew: add jq`, `deploy: skip .config`.
- Conventional prefixes welcome (`docs:`, `feat:`, `fix:`) when clear.
- PRs: include purpose, summary of changes, affected hosts, and any manual steps (`reboot`, `brew services`).
- Link issues/ADRs when relevant; add screenshots for macOS settings only if UI changes are shown.

## Security & Configuration Tips
- Never commit secrets; exclude private files via `EXCLUSIONS`.
- `~/.config` is opt-in: explicitly include only what you intend to manage.
- Follow the package policy: CLI tools via Devbox; GUI apps via Homebrew Cask; long‑running daemons via `brew services`.

## Notes

- The `.config` directory is not version controlled by default - use `.gitignore` exclusions to manage specific config files
- To add new `.config` subdirectories to git management:
  1. Add `!/<subdirectory_name>` to `.config/.gitignore`
  2. Run `git add .config/<subdirectory_name>` to stage the files
  3. Commit the changes including the updated `.config/.gitignore`
- Devbox replaced Nix as the primary package manager but some legacy Nix cleanup utilities remain
- Fish shell is the primary shell with extensive plugin ecosystem via Fisher
- macOS system defaults are automated via `etc/mac_defaults.sh`
