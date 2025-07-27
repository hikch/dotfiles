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
$ make
deploy                         Deploy dotfiles.
devbox-install                 Install Devbox package manager
devbox-global-install          Install global Devbox packages
fish                           Install fish plug-ins & Add direnv hook
homebrew                       Install homebrew packages
init                           Initialize.
mac-defaults                   Setup macos settings
nix-clean-backups              Clean up old Nix installer backups
vim                            Install vim plug-ins
```

## Note

### .config

.config is not managed by git.
Use .gitignore to remove exclusions only for files you want to manage.

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
