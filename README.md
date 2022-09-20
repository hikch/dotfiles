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
1. make nix-darwin
1. make home-manager
1. make init

## Usage

``` sh
$ cd ~/dotfiles
$ make
darwin-rebuild-switch          Run darwin-rebuild switch
deploy                         Deploy dotfiles.
home-manager-switch            Run home-manager switch
home-manager                   Install home-manager
homebrew                       Install homebrew packages
init                           Initialize.
mac-defaults                   Setup macos settings
nix-darwin                     Install nix-darwin
nix                            Install nix
vim                            Install vim plug-ins

**Note** init is done after making nix, nix-darwin, and home-manager.
```

## Toolset

- [direnv](https://github.com/direnv/direnv)
- [fish](https://fishshell.com)
- [homebrew](https://brew.sh)
- [jq](https://stedolan.github.io/jq/)
- [lorri](https://github.com/nix-community/lorri)
- [macvim](https://macvim-dev.github.io/macvim/)
- [nix](https://nixos.org), [nix-darwin](https://github.com/LnL7/nix-darwin), [home-manager](https://github.com/nix-community/home-manager)
and more...

## TODO

- [ ] Use nix-darwin to manage the settings in mac defaults
- [x] Use the defaults command to automate MacOS settings
- [x] Switch to package management using nix
- [x] Switch to package management using nix-darwin
- [x] Seitch to dotfiles management using nix home-manager

I am wondering whether to manage dot files with nix.
If I can't install nix at my work place, it is easier to use the current script.
