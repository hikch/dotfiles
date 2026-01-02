# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages macOS development environment configuration using a hybrid approach of traditional symlink deployment and modern package management via Devbox (and previously Nix). The setup manages shell configurations, development tools, applications, and system settings.

## Architecture

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

## AI Tools Configuration

This repository includes configuration for AI development tools:

### Claude Code
- **Configuration File**: `.claude/CLAUDE.md` (symlinked to `~/.claude/CLAUDE.md`)
- **Purpose**: Provides environment context and available package information
- **Deployment**: Individual file deployment (directory excluded, specific file included)

### Gemini CLI  
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
- **`.claude`**: Directory excluded (`EXCLUSIONS`), but `.claude/CLAUDE.md` individually included (`CANDIDATES`)
- **`.config`**: Directory symlinked, but contents selectively managed via `.config/.gitignore`
- **Partial links**: `.local/share/devbox/global/default` is symlinked while `.local` parent is excluded (`PARTIAL_LINKS`)

To modify what gets deployed:
1. Edit `CANDIDATES` to add new deploy targets
2. Edit `EXCLUSIONS` to exclude files/directories
3. Edit `PARTIAL_LINKS` to add selective nested path symlinks
4. Run `make deploy` to apply changes

## Notes

- The `.config` directory is not version controlled by default - use `.gitignore` exclusions to manage specific config files
- To add new `.config` subdirectories to git management:
  1. Add `!/<subdirectory_name>` to `.config/.gitignore` 
  2. Run `git add .config/<subdirectory_name>` to stage the files
  3. Commit the changes including the updated `.config/.gitignore`
- Devbox replaced Nix as the primary package manager but some legacy Nix cleanup utilities remain
- Fish shell is the primary shell with extensive plugin ecosystem via Fisher
- macOS system defaults are automated via `etc/mac_defaults.sh`