.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""


# Load deployment configuration from external files
BASE_EXCLUSIONS := $(shell grep -v '^\#' EXCLUSIONS | grep -v '^$$' | tr '\n' ' ')
CANDIDATES_PATTERNS := $(shell grep -v '^\#' CANDIDATES | grep -v '^$$' | tr '\n' ' ')
#
# 部分的にリンクしたい相対パス（dotfiles 配下）
PARTIAL_LINKS := .local/share/devbox/global/default

# PARTIAL_LINKS からトップレベルディレクトリを抽出し EXCLUSIONS に追加
PARTIAL_TOPS := $(sort $(foreach p,$(PARTIAL_LINKS),$(firstword $(subst /, ,$(p)))))
EXCLUSIONS := $(BASE_EXCLUSIONS) $(PARTIAL_TOPS)

# 検出対象を CANDIDATES ファイルから展開
CANDIDATES := $(foreach pattern,$(CANDIDATES_PATTERNS),$(wildcard $(pattern)))
DOTFILES   = $(filter-out $(EXCLUSIONS), $(CANDIDATES))

DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OSNAME     := $(shell uname -s)


.PHONY: init
init: deploy nix-clean-backups devbox-install devbox-global-install homebrew fish mac-defaults ## Initialize.

.PHONY: deploy
deploy: ## Deploy dotfiles.
	@if ! [ -L $(HOME)/.config ]; then mv $(HOME)/.config $(HOME)/.config~; fi
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@$(foreach path,$(PARTIAL_LINKS), \
		mkdir -p $(HOME)/$(dir $(path)); \
		rm -rf $(HOME)/$(path); \
		ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path);)
	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh


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
fish: ## Install fish plug-ins & Add direnv hook
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

.PHONY: nix-install
nix-install:
	@echo "📦 Installing Nix with --daemon option..."
	@curl -L https://nixos.org/nix/install | sh -s -- --daemon

.PHONY: devbox-install
devbox-install:
	@echo "🧰 Installing Devbox..."
	curl -fsSL https://get.jetify.com/devbox | bash


.PHONY: devbox-global-install
devbox-global-install: ## devbox global install
	@echo "🧰 Installing Devbox globally..."
	@devbox global install 2>/dev/null || devbox global update

.PHONY: nix-clean-backups
nix-clean-backups:
	@echo "🧼 Cleaning up old Nix installer backup files..."

	@for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc; do \
	  backup="$$file.backup-before-nix"; \
	  if [ -f "$$backup" ]; then \
	    timestamp=$$(date +%Y%m%d%H%M%S); \
	    echo "📁 Found backup: $$backup"; \
	    sudo cp "$$backup" "$$backup.bak.$$timestamp"; \
	    echo "📦 Backed up $$backup to $$backup.bak.$$timestamp"; \
	    sudo cp "$$file" "$$file.bak.$$timestamp"; \
	    echo "📦 Backed up $$file to $$file.bak.$$timestamp"; \
	    sudo mv "$$backup" "$$file"; \
	    echo "✅ Restored $$file from $$backup"; \
	  else \
	    echo "✅ No backup found for $$file"; \
	  fi; \
	done

	@echo ""
	@echo "✅ All conflicting backups resolved. You can now run:"
	@echo "   make nix-install"
