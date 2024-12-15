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

To install the packages and applications, follow these steps.

Start and run the shell for each step to enable the package manager.

1. make nix
1. make home-manager
1. make init

## Usage

``` sh
$ cd ~/dotfiles
$ make
deploy                         Deploy dotfiles.
fish                           Install fish plug-ins & Add direnv hook
home-manager-switch            Run home-manager switch
home-manager                   Install home-manager
homebrew                       Install homebrew packages
init                           Initialize.
mac-defaults                   Setup macos settings
nix-update                     Update nix
nix                            Install nix
vim                            Install vim plug-ins

**Note** init is done after making nix, and home-manager
```

## Note

### .config

.config is not managed by git.
Use .gitignore to remove exclusions only for files you want to manage.

## Toolset

- [direnv](https://github.com/direnv/direnv)
- [fish](https://fishshell.com)
- [homebrew](https://brew.sh)
- [jq](https://stedolan.github.io/jq/)
- [macvim](https://macvim-dev.github.io/macvim/)
- [nix](https://nixos.org), [home-manager](https://github.com/nix-community/home-manager)
and more...

## TODO

- [ ] Make script for creating ssh settings when adding a remote host.
- [ ] Use nix-darwin to manage the settings in mac defaults
- [x] Use the defaults command to automate MacOS settings
- [x] Switch to package management using nix
- [x] Seitch to dotfiles management using nix home-manager

I am wondering whether to manage dot files with nix.
If I can't install nix at my work place, it is easier to use the current script.
