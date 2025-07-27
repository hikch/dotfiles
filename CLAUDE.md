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

## Notes

- The `.config` directory is not version controlled by default - use `.gitignore` exclusions to manage specific config files
- Devbox replaced Nix as the primary package manager but some legacy Nix cleanup utilities remain
- Fish shell is the primary shell with extensive plugin ecosystem via Fisher
- macOS system defaults are automated via `etc/mac_defaults.sh`