.PHONY: help deploy init xcode homebrew vim elm fish

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


EXCLUSIONS := .DS_Store .git .gitmodules .gitignore .travis.yml
CANDIDATES := $(wildcard .??*) bin etc
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))
DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))


deploy: ## Deploy dotfiles.
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh


init: deploy xcode homebrew vim elm fish ## Initialize.


xcode: ## Install xcode unix tools
	xcode-select --install || True


homebrew: /opt/homebrew/bin/brew ## Install homebrew and packages


/opt/homebrew/bin/brew:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; brew bundle --global || True


vim: homebrew ## Install vim plug-ins
	curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh ~/.cache/dein && rm installer.sh


elm: homebrew ## Install elm, elm-test, elm-format, elm-app
	npm install -g \
		elm \
		elm-test \
		elm-format \
		create-elm-app \
		@elm-tooling/elm-language-server
		|| true


fish: homebrew # Install fish plug-ins
	/opt/homebrew/bin/fish -c \
		"curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
	
	touch .config/fish/fish_plugins
	/opt/homebrew/bin/fish -c "fisher update"


