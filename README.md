# dotfiles

## Installation

Run this:

``` sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/hikch/dotfiles/main/bootstrap.sh)"
```

or

``` sh
git clone git@github.com:hikch/dotfiles.git ~/dotfiles
cd ~/dotfiles
make deploy

```

This will symlink the appropriate files in dotfiles to your home directory.
Everything is configured and tweaked within `~/dotfiles`.

⚠️  Please make sure you understand the script before running it!

### Install packages and applications

To install the packages and applications, run:

``` sh
make init
```

This will install Devbox, configure global packages, install Homebrew applications, setup Fish shell, and apply macOS defaults.

## Usage

### Core Commands

``` sh
$ cd ~/dotfiles
$ make help
deploy                         Deploy dotfiles.
devbox-global-install          devbox global install
fish                           Install fish plug-ins & Add direnv hook
homebrew                       Install homebrew packages
init                           Initialize.
mac-defaults                   Setup macos settings
vim                            Install vim plug-ins
```

### Dry-run Deploy (Safe Test)

Quickly validate what `make deploy` would symlink without touching your real home by using a temporary HOME:

``` sh
HOME=$(mktemp -d) make deploy
```

This simulates deployment in an isolated sandbox directory so you can review output safely.

### Homebrew Bundle Management

New Brewfile management with host-specific configuration:

``` sh
# Package operations
make brew/setup                # Install/upgrade packages from .Brewfile (and host include)
make brew/check                # Check if everything is satisfied (with details)
make brew/cleanup              # Show removable packages not in Brewfiles  
make brew/cleanup-force        # Remove packages not in Brewfiles
make brew/upgrade              # Upgrade all (formulae & casks)

# Adding packages
make brew/cask-add NAME=app    # Add GUI app to common .Brewfile
make brew/host-cask-add NAME=app # Add GUI app to current host Brewfile

# Utilities
make brew/dump-actual          # Snapshot current state to Brewfile.actual
```

## Configuration

### .config

.config is not managed by git.
Use .gitignore to remove exclusions only for files you want to manage.

### Package Management Strategy

This repository uses a hybrid approach for optimal package management:

- **Devbox**: CLI tools and development utilities (Node.js, jq, ripgrep, mas, etc.)
- **Homebrew Cask**: GUI applications only (browsers, editors, productivity apps)
- **Host-specific configuration**: Different packages per machine via `hosts/` directory

#### Service Management Policy

Background services are managed based on their scope:

- **`brew services`**: System-wide, always-on daemons (tailscaled, syncthing, shared databases, GUI agents)
  - Integrated with macOS LaunchAgents/Daemons
  - Persist across reboots and user sessions
- **`devbox services`**: Project-scoped, version-pinned dependencies (development databases, local services)
  - Started/stopped with project environments
  - Ensures reproducibility across different projects

**Rule of thumb**: System-wide → `brew services`, project-specific → `devbox services`

#### Homebrew Host Configuration

The `.Brewfile` supports automatic host-specific includes:

```
dotfiles/
  .Brewfile                    # Common GUI applications
  hosts/
    iMac-2020.Brewfile        # iMac-specific packages (e.g., server tools)
    MacBookAir2025.Brewfile   # MacBookAir-specific packages (e.g., dev tools)
```

Host files are automatically detected using `hostname -s` and included during `brew bundle` operations.

### Deployment Settings

The deployment behavior is controlled by external configuration files:

- **`CANDIDATES`** - Files and directories to be symlinked to `$HOME` (whitelist)
- **`EXCLUSIONS`** - Files and directories to exclude from deployment
- **`PARTIAL_LINKS`** - Nested paths to symlink individually (parent dirs auto-excluded)

To modify what gets deployed:
1. Edit `CANDIDATES` to add new deploy targets
2. Edit `EXCLUSIONS` to exclude files/directories
3. Edit `PARTIAL_LINKS` to add selective nested path symlinks
4. Run `make deploy` to apply changes

### Syncthing Usage

Syncthing installation varies by host:

**Common (all machines):**
- GUI application via `cask "syncthing"`

**Host-specific (iMac only):**
- CLI version via `brew "syncthing"` for server functionality

**Usage:**
``` sh
# Desktop use (all machines)
open /Applications/Syncthing.app

# Server use (iMac only)  
brew services start syncthing
brew services stop syncthing
```

## Toolset

- [devbox](https://www.jetify.com/devbox) - Primary package manager for development tools
- [direnv](https://github.com/direnv/direnv)
- [fish](https://fishshell.com) - Shell with Fisher plugin management
- [homebrew](https://brew.sh) - macOS applications and some CLI tools
- [jq](https://stedolan.github.io/jq/)
- [macvim](https://macvim-dev.github.io/macvim/)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [tmux](https://github.com/tmux/tmux)
and more...

## TODO

- [ ] Make script for creating ssh settings when adding a remote host.
- [ ] Split Makefile into modular files (make/deploy.mk, make/homebrew.mk, make/devtools.mk, make/macos.mk)
- [x] Use the defaults command to automate MacOS settings
- [x] Switch to package management using Devbox
- [x] Migrate from Nix to Devbox for better compatibility
