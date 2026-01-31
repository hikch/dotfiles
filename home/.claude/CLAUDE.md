# Repository Guidelines

This file provides guidance to AI coding assistants (Claude Code, Gemini CLI, etc.) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages macOS development environment configuration using a hybrid approach of traditional symlink deployment and modern package management via Devbox (and previously Nix). The setup manages shell configurations, development tools, applications, and system settings.

### Package Management Strategy
- **Devbox**: Primary package manager for development tools (defined in `home/.local/share/devbox/global/default/devbox.json`)
- **Homebrew**: macOS applications and some CLI tools (defined in `.Brewfile`)
- **Fish Shell**: Shell configuration with plugin management via Fisher

### Configuration Structure
- **Symlink Deployment**: Core dotfiles from `home/` are symlinked to `$HOME` via `make deploy`
- **Partial Links**: Some nested paths like `.local/share/devbox/global/default` are selectively symlinked
- **Separated Concerns**: Deployment files in `home/`, package management files in root

### Key Components
- `Makefile`: Root orchestrator (delegates to `home/Makefile` for deployment)
- `home/Makefile`: Deployment-specific targets
- `home/`: Directory containing all files to be deployed to `$HOME`
- `bootstrap.sh`: Remote installation script that clones repo and runs `make deploy`
- `home/bin/`: Custom vim/macvim wrapper scripts
- `home/etc/`: System configuration scripts (macOS defaults, terminal themes)

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

```
~/dotfiles/
  Makefile              # Root orchestrator (delegates to home/)
  .Brewfile             # Homebrew packages (GUI apps, CLI tools)
  hosts/                # Host-specific Brewfiles
  apps/                 # Application-specific configs (iTerm2, etc.)
  .claude/              # Project-level AI settings (not deployed)
  home/                 # Files to be deployed to $HOME
    Makefile            # Deployment targets
    CANDIDATES          # Whitelist of files to deploy
    EXCLUSIONS          # Files to exclude
    PARTIAL_LINKS       # Nested paths to symlink
    .vimrc              # -> ~/.vimrc
    .gitconfig          # -> ~/.gitconfig
    .claude/            # -> ~/.claude/ (global AI settings)
    .gemini/            # -> ~/.gemini/ (global AI settings)
    .config/            # Partial links (fish, git, gh)
    .local/             # Partial links (devbox)
    bin/                # -> ~/bin
    etc/                # -> ~/etc
```

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
make test             # Run deployment tests in sandbox
make deploy/dry-run   # Preview deployment without changes
```

## Development Workflow

1. Modify dotfiles in `home/` directory
2. Run `make deploy` to update symlinks
3. For new packages, add to appropriate package manager:
   - Development tools → `home/.local/share/devbox/global/default/devbox.json`
   - GUI applications → `.Brewfile`
   - Fish plugins → `home/.config/fish/fish_plugins`

### AI Tools Configuration

This repository separates project-level and global AI settings:

**Project Settings (not deployed):**
- `.claude/` - Project-specific Claude Code settings
- Contains `CLAUDE.md` (symlink to `AGENTS.md`) for repository guidelines

**Global Settings (deployed to $HOME):**
- `home/.claude/` → `~/.claude/` - Global Claude Code settings
- `home/.gemini/` → `~/.gemini/` - Global Gemini CLI settings

This separation allows:
- Repository-specific AI behavior via project settings
- Consistent global defaults via deployed settings
- No conflicts between project and global configurations

## Deployment Configuration

Deployment is controlled by files in `home/`:

- **`home/CANDIDATES`**: Files/patterns to deploy (whitelist)
- **`home/EXCLUSIONS`**: Files to exclude from deployment
- **`home/PARTIAL_LINKS`**: Nested paths to symlink individually

### How Deployment Works

1. Files matching `CANDIDATES` patterns in `home/` are symlinked to `$HOME`
2. Files in `EXCLUSIONS` are skipped
3. `PARTIAL_LINKS` items are symlinked individually (parent dirs become real directories)

### Special Cases
- **`.config` and `.local`**: Real directories in `$HOME`, with selective symlinks inside
- **`.claude` and `.gemini`**: Full directory symlinks to `home/.claude/` and `home/.gemini/`

To modify what gets deployed:
1. Edit `home/CANDIDATES` to add new deploy targets
2. Edit `home/EXCLUSIONS` to exclude files/directories
3. Edit `home/PARTIAL_LINKS` to add selective nested path symlinks
4. Run `make deploy` to apply changes

### PARTIAL_LINKS Migration

Use migration targets when converting between symlink types:

```bash
# Convert full symlink to real directory with partial links
make migrate-top-symlink-to-real

# Add a new partial link (real dir -> symlink)
make migrate-add-partial-link path=.config/uv

# Remove a partial link (symlink -> real dir)
make migrate-remove-partial-link path=.config/git
```

## Build, Test, and Development Commands
- `make help`: list available tasks.
- `make deploy`: symlink managed files into `$HOME` (idempotent); fixes `~/.ssh` perms.
- `make deploy/dry-run`: preview what would be deployed.
- `make test`: run deployment tests in sandbox.
- `make init`: first-time setup (Devbox, Homebrew, Fish, macOS defaults).
- `make homebrew` / `make brew/*`: manage packages via Brewfile(s).
- `make vim` / `make fish`: install editor/shell plugins.
- Tip: Dry-run deploy in a sandbox: `HOME=$(mktemp -d) make -C home deploy`.

## Coding Style & Naming Conventions
- Shell: prefer POSIX `sh` for portability; guard scripts with `set -eu` when safe.
- Makefile: use tabs for recipes; keep targets descriptive (e.g., `brew/upgrade`).
- Brewfiles: name host files exactly `hosts/<hostname>.Brewfile`.
- Paths: keep repo-relative paths; symlink targets live under `home/`.

## Testing Guidelines
- Validate changes with `make help`, `make deploy` (sandboxed), and `make brew/check`.
- Run `make test` to verify deployment in a sandbox environment.
- For host logic, test using a stub: `HOST=$(hostname -s) make brew/setup`.
- Keep deployments reversible; avoid destructive operations in default targets.

## Commit & Pull Request Guidelines
- Commits: imperative, concise, scoped. Examples: `brew: add jq`, `deploy: skip .config`.
- Conventional prefixes welcome (`docs:`, `feat:`, `fix:`) when clear.
- PRs: include purpose, summary of changes, affected hosts, and any manual steps (`reboot`, `brew services`).
- Link issues/ADRs when relevant; add screenshots for macOS settings only if UI changes are shown.

## Security & Configuration Tips
- Never commit secrets; exclude private files via `home/EXCLUSIONS`.
- `~/.config` is opt-in: explicitly include only what you intend to manage via `home/PARTIAL_LINKS`.
- Follow the package policy: CLI tools via Devbox; GUI apps via Homebrew Cask; long-running daemons via `brew services`.

## Notes

- Dotfiles to be deployed live in `home/`, not in the repository root
- The `.config` directory uses PARTIAL_LINKS for selective management
- Project-level AI settings (`.claude/`) are separate from global settings (`home/.claude/`)
- Devbox replaced Nix as the primary package manager
- Fish shell is the primary shell with extensive plugin ecosystem via Fisher
- macOS system defaults are automated via `home/etc/mac_defaults.sh`
