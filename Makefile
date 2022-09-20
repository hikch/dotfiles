.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "**Note** init is done after making nix, nix-darwin, and home-manager."
	@echo ""


EXCLUSIONS := .DS_Store .git .gitmodules .gitignore .travis.yml
CANDIDATES := $(wildcard .??*) bin etc
DOTFILES   = $(filter-out $(EXCLUSIONS), $(CANDIDATES))
DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OSNAME     := $(shell uname -s)

define INSTALL_NIX_HOME_MANAGER
endef
export INSTALL_NIX_HOME_MANAGER


.PHONY: nix
nix: /nix ## Install nix
/nix: # Install nix
	@echo "Install nix"
	curl -L https://nixos.org/nix/install |sh


.PHONY: nix-darwin
nix-darwin: ## Install nix-darwin
ifeq  "$(OSNAME)" "Darwin"
	@echo "Install nix-darwin..."
	@which darwin-rebuild || \
		nix-build \
			https://github.com/LnL7/nix-darwin/archive/master.tar.gz \
			-A installer
	./result/bin/darwin-installer
endif


.PHONY: home-manager
home-manager: ## Install home-manager
	@echo "Install nix home-manage..."
	@which home-manager || \
		( nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager; \
		  nix-channel --update; \
		  nix-shell '<home-manager>' -A install; \
		)


.PHONY: init
init: deploy darwin-rebuild-switch home-manager-switch homebrew fish mac-defaults ## Initialize.

.PHONY: deploy
deploy: ## Deploy dotfiles.
	@if ! [ -L $(HOME)/.config ]; then mv $(HOME)/.config $(HOME)/.config~; fi
	@if ! [ -L $(HOME)/.nixpkgs ]; then mv $(HOME)/.nixpkgs $(HOME)/.nixpkgs~; fi
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh

.PHONY: home-manager-switch
home-manager-switch: ## Run home-manager switch
	which home-manager \
		&& home-manager switch


.PHONY: darwin-rebuild-switch
darwin-rebuild-switch: ## Run darwin-rebuild switch
	which darwin-rebuild \
		&& darwin-rebuild switch

.PHONY: homebrew
homebrew:  ## Install homebrew packages
ifeq  "$(OSNAME)" "Darwin"
	ls /opt/homebrew/bin/brew || \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		brew bundle --file="./.Brewfile" 2>&1 || true
endif


.PHONY: vim
vim: ## Install vim plug-ins
	which vim && curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh ~/.cache/dein && rm installer.sh
	which vim && vim -c 'call dein#recache_runtimepath()' -c 'q'


.PHONY: fish
fish: # Install fish plug-ins & Add direnv hook
	which fish && fish -c \
		"curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
	which fish && touch .config/fish/fish_plugins
	fish -c "fisher update"


.PHONY: mac-defaults
mac-defaults: ## Setup macos settings
ifeq  "$(OSNAME)" "Darwin"
	sh etc/mac_defaults.sh
	@echo "Reboot to reflect settings."
endif
