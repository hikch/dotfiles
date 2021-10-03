.PHONY: help deploy init xcode homebrew vim elm fish

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


EXCLUSIONS := .DS_Store .git .gitmodules .gitignore .travis.yml
CANDIDATES := $(wildcard .??*) bin etc
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))
DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OSNAME     := $(shell uname -s)


deploy: ## Deploy dotfiles.
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh


init: deploy xcode homebrew vim elm fish ## Initialize.


xcode: ## Install xcode unix tools
ifeq  "$(OSNAME)" "Darwin"
	xcode-select --install || True
endif


homebrew: /opt/homebrew/bin/brew ## Install homebrew packages
ifeq  "$(OSNAME)" "Darwin"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; brew bundle --global || True
endif


/opt/homebrew/bin/brew:
ifeq  "$(OSNAME)" "Darwin"
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [ ! -e /opt/homebrew ]; then
		ln -s /usr/local /opt/homebrew
	fi
endif


vim: homebrew ## Install vim plug-ins
ifneq "" "$(shell which vim >> /dev/null)"
	curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh ~/.cache/dein && rm installer.sh
endif

elm: homebrew ## Install elm, elm-test, elm-format, elm-app
ifneq "" "$(shell which npm >> /dev/null)"
	npm install -g \
		elm \
		elm-test \
		elm-format \
		create-elm-app \
		@elm-tooling/elm-language-server \
		|| true
endif


fish: homebrew # Install fish plug-ins
ifneq "" "$(shell which fish >> /dev/null)"
  ifneq "" "$(shell type fisher 2> /dev/null)"
	/opt/homebrew/bin/fish -c \
		"curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
  endif
	touch .config/fish/fish_plugins
	/opt/homebrew/bin/fish -c "fisher update"
endif
