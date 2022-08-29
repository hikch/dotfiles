.PHONY: help deploy init xcode homebrew vim elm fish

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


EXCLUSIONS := .DS_Store .git .gitmodules .gitignore .travis.yml
CANDIDATES := $(wildcard .??*) bin etc
DOTFILES   = $(filter-out $(EXCLUSIONS), $(CANDIDATES))
DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OSNAME     := $(shell uname -s)

# commands
MACKUP	   = $(shell which mackup)


init: xcode homebrew deploy elm fish ## Initialize.


deploy: .mackup.cfg ## Deploy dotfiles.
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh


mackup-check-backup: .mackup.cfg ## Check need back up with mackup
ifdef MACKUP
	@$(MACKUP) -n backup
endif


mackup-backup: .mackup.cfg ## Back up with mackup
ifdef MACKUP
	$(MACKUP) backup
endif


mackup-restore: .mackup.cfg ## Restore with mackup
ifdef MACKUP
	$(MACKUP) restore
endif


mackup-uninstall: .mackup.cfg ## Uninstall with mackup
ifdef MACKUP
	$(MACKUP) uninstall
endif


.mackup.cfg: mackup.m4
ifdef MACKUP
	m4 $? -D__path__=`hostname` > $@
endif


xcode: ## Install xcode unix tools
ifeq  "$(OSNAME)" "Darwin"
	xcode-select --install || True
endif


homebrew: /opt/homebrew/bin/brew ## Install homebrew packages
ifeq  "$(OSNAME)" "Darwin"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	    brew bundle --global 2>&1 \
	    |awk '/has failed!/{print $$2}' |xargs brew reinstall -f;
endif


/opt/homebrew/bin/brew:
ifeq  "$(OSNAME)" "Darwin"
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
	if [ ! -e /opt/homebrew ]; then \
		sudo ln -s /usr/local /opt/homebrew ; \
	fi
endif


vim: homebrew ## Install vim plug-ins
	which vim && curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh ~/.cache/dein && rm installer.sh
	which vim && vim -c 'call dein#recache_runtimepath()' -c 'q'


elm: homebrew ## Install elm, elm-test, elm-format, elm-app
	which npm && npm install -g \
		elm \
		elm-test \
		elm-format \
		create-elm-app \
		@elm-tooling/elm-language-server \
		|| true


fish: homebrew # Install fish plug-ins
	which fish && /opt/homebrew/bin/fish -c \
		"curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
	which fish && touch .config/fish/fish_plugins
	/opt/homebrew/bin/fish -c "fisher update"

mac-defaults: ## Setup macos settings
ifeq  "$(OSNAME)" "Darwin"
	etc/mac_defaults.sh
endif
