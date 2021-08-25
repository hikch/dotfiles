.PHONY: help run

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


init: deploy xcode homebrew vim elm-app fish ## Initialize.


xcode: ## Install xcode unix tools
	xcode-select --install || True


homebrew: xcode ## Install homebrew
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; brew bundle --global || True


vim: homebrew ## Install dein for vim
	curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh ~/.cache/dein && rm installer.sh


elm-app: homebrew ## Install create-elm-app
	npm install -g \
		create-elm-app \
		|| true


fisher: homebrew # Install fisher for fish
	/bin/zsh -c "curl -sL https://git.io/fisher \
		| source \
		&& fisher install jorgebucaran/fisher" \
		|| true


