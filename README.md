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

## Configuration

### .config

.config is not managed by git.
Use .gitignore to remove exclusions only for files you want to manage.

### Deployment Settings

The deployment behavior is controlled by external configuration files:

- **`CANDIDATES`** - Files and directories to be symlinked to `$HOME` (whitelist)
- **`EXCLUSIONS`** - Files and directories to exclude from deployment

To modify what gets deployed:
1. Edit `CANDIDATES` to add new deploy targets
2. Edit `EXCLUSIONS` to exclude files/directories  
3. Run `make deploy` to apply changes

### Syncthing Usage

Both GUI and CLI versions are installed via Brewfile:

**For desktop use (MacBook Air, etc.):**
``` sh
# Launch GUI application
open /Applications/Syncthing.app
```

**For server use (iMac, etc.):**
``` sh
# Start as background service
brew services start syncthing

# Stop service
brew services stop syncthing

# Manual run (no browser, no auto-restart)
$(brew --prefix syncthing)/bin/syncthing -no-browser -no-restart
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
- [x] Use the defaults command to automate MacOS settings
- [x] Switch to package management using Devbox
- [x] Migrate from Nix to Devbox for better compatibility
