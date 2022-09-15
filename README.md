# dotfiles

## Install

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

## Usage

``` sh
$ cd ~/dotfiles
$ make
deploy                         Deploy dotfiles.
elm                            Install elm, elm-test, elm-format, elm-app
homebrew                       Install homebrew packages
init                           Initialize.
mackup-backup                  Back up with mackup
mackup-check-backup            Check need back up with mackup
mackup-restore                 Restore with mackup
mackup-uninstall               Uninstall with mackup
vim                            Install vim plug-ins
xcode                          Install xcode unix tools
```

## TODO

- Switch to package management using nix 
- Seitch to dotfiles management using home-manager
