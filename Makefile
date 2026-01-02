.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""


# ========================================
# Deployment Configuration
# ========================================
# Load configuration from external files (UNIX-style whitelist/blacklist approach)
#
# CANDIDATES:     Whitelist of files/patterns to deploy
# EXCLUSIONS:     Blacklist of files/patterns to exclude
# PARTIAL_LINKS:  Nested paths to symlink individually (parent dirs are auto-excluded)

# Load whitelist patterns and blacklist
EXCLUSIONS_FROM_FILE := $(shell grep -v '^\#' EXCLUSIONS | grep -v '^$$' | tr '\n' ' ')
CANDIDATES_PATTERNS := $(shell grep -v '^\#' CANDIDATES | grep -v '^$$' | tr '\n' ' ')

# Load partial link paths (nested paths to symlink individually)
PARTIAL_LINKS := $(shell grep -v '^\#' PARTIAL_LINKS | grep -v '^$$' | tr '\n' ' ')

# Auto-exclude top-level directories of partial links
# Example: .local/share/devbox/global/default -> .local
PARTIAL_TOPS := $(sort $(foreach p,$(PARTIAL_LINKS),$(firstword $(subst /, ,$(p)))))

# Combine all exclusions
EXCLUSIONS := $(EXCLUSIONS_FROM_FILE) $(PARTIAL_TOPS)

# Expand wildcard patterns and apply exclusion filters
CANDIDATES := $(foreach pattern,$(CANDIDATES_PATTERNS),$(wildcard $(pattern)))
DOTFILES := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OSNAME     := $(shell uname -s)


.PHONY: init
init: deploy devbox-install devbox-global-install homebrew fish mac-defaults pmset-settings ## Initialize.

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

.PHONY: deploy/dry-run
deploy/dry-run:  ## Preview deployment without making changes
	@echo "=== Deployment Preview ==="
	@echo "Standard symlinks:"
	@$(foreach val, $(DOTFILES), echo "  $(abspath $(val)) -> $(HOME)/$(val)";)
	@echo ""
	@echo "Partial symlinks:"
	@$(foreach path,$(PARTIAL_LINKS), echo "  $(DOTPATH)/$(path) -> $(HOME)/$(path)";)

.PHONY: status
status:  ## Show repository and package status
	@echo "=== Git Status ==="
	@git status --short
	@echo ""
	@echo "=== Broken Symlinks in HOME ==="
	@find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" || echo "No broken symlinks found"
	@echo ""
	@$(MAKE) --no-print-directory packages/status


# ==========================================
# Homebrew Bundle Operations
# ==========================================

SHELL := /bin/bash
ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOST  := $(shell hostname -s)
BREWFILE          := $(ROOT)/.Brewfile
HOST_BREWFILE     := $(ROOT)/hosts/$(HOST).Brewfile
LOCAL_BREWFILE    := $(ROOT)/.Brewfile.local

.PHONY: homebrew
homebrew:  ## Install homebrew packages
ifeq  "$(OSNAME)" "Darwin"
	ls /opt/homebrew/bin/brew || \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		brew bundle --file="./.Brewfile" 2>&1 || true
endif

# ---- Brew bundle operations ----
.PHONY: brew/setup
brew/setup: ## Install/upgrade packages from .Brewfile (and host include)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle --file=$(BREWFILE)

.PHONY: brew/check
brew/check: ## Check if everything is satisfied (with details)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle check --file=$(BREWFILE) --verbose

.PHONY: brew/cleanup
brew/cleanup: ## Show removable packages not in Brewfiles
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle cleanup --file=$(BREWFILE)
	@echo "Run 'make brew/cleanup-force' to actually remove."

.PHONY: brew/cleanup-force
brew/cleanup-force: ## Remove packages not in Brewfiles
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle cleanup --file=$(BREWFILE) --force

.PHONY: brew/outdated
brew/outdated: ## Show outdated packages
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated || true

.PHONY: brew/upgrade
brew/upgrade: ## Upgrade all (formulae & casks)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew update && brew upgrade && brew upgrade --cask || true

.PHONY: brew/dump-actual
brew/dump-actual: ## Snapshot current state to Brewfile.actual
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle dump --describe --force --file=$(ROOT)/Brewfile.actual
	@echo "Wrote snapshot: $(ROOT)/Brewfile.actual"

# ---- convenience for adding entries ----
.PHONY: brew/add
brew/add: ## Add package to common .Brewfile (e.g., make brew/add NAME=jq)
	@test -n "$(NAME)" || (echo "NAME is required (e.g., make brew/add NAME=jq)"; exit 1)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle add --file=$(BREWFILE) $(NAME)

.PHONY: brew/host-add
brew/host-add: ## Add package to host Brewfile (e.g., make brew/host-add NAME=jq-foo)
	@test -n "$(NAME)" || (echo "NAME is required (e.g., make brew/host-add NAME=jq)"; exit 1)
	@mkdir -p $(ROOT)/hosts
	@if [ ! -f $(HOST_BREWFILE) ]; then echo "# $(HOST) only" > $(HOST_BREWFILE); fi
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle add --file=$(HOST_BREWFILE) $(NAME)

.PHONY: brew/cask-add
brew/cask-add: ## Add cask to common .Brewfile (e.g., make brew/cask-add NAME=iterm2)
	@test -n "$(NAME)" || (echo "NAME is required (e.g., make brew/cask-add NAME=iterm2)"; exit 1)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle add --file=$(BREWFILE) --cask $(NAME)

.PHONY: brew/host-cask-add
brew/host-cask-add: ## Add cask to host Brewfile (e.g., make brew/host-cask-add NAME=anydesk)
	@test -n "$(NAME)" || (echo "NAME is required (e.g., make brew/host-cask-add NAME=anydesk)"; exit 1)
	@mkdir -p $(ROOT)/hosts
	@if [ ! -f $(HOST_BREWFILE) ]; then echo "# $(HOST) only" > $(HOST_BREWFILE); fi
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle add --file=$(HOST_BREWFILE) --cask $(NAME)

.PHONY: brew/tap-add
brew/tap-add: ## Add tap to common .Brewfile (e.g., make brew/tap-add NAME=homebrew/ffmpeg)
	@test -n "$(NAME)" || (echo "NAME is required (e.g., make brew/tap-add NAME=homebrew/ffmpeg)"; exit 1)
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew tap $(NAME) && brew bundle dump --force --file=$(BREWFILE)


# ==========================================
# Unified Package Management (Devbox + Homebrew)
# ==========================================

.PHONY: packages/install
packages/install: devbox-global-install homebrew  ## Install all packages (Devbox + Homebrew)

.PHONY: packages/update
packages/update:  ## Update all packages
	@echo "=== Updating Devbox packages ==="
	@devbox global update
	@echo ""
	@echo "=== Updating Homebrew packages ==="
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew update && brew upgrade && brew upgrade --cask || true

.PHONY: packages/status
packages/status:  ## Show package status
	@echo "=== Devbox packages ==="
	@devbox global list
	@echo ""
	@echo "=== Homebrew outdated ==="
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated || true

.PHONY: packages/cleanup
packages/cleanup: brew/cleanup  ## Clean up unused packages
	@echo "Note: Devbox cleanup not yet implemented"


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

.PHONY: pmset-settings
pmset-settings: ## Setup power management settings (model-specific)
ifeq  "$(OSNAME)" "Darwin"
	sh etc/pmset_settings.sh
endif

.PHONY: devbox-install
devbox-install:
	@echo "🧰 Installing Devbox..."
	curl -fsSL https://get.jetify.com/devbox | bash


.PHONY: devbox-global-install
devbox-global-install: ## devbox global install
	@echo "🧰 Installing Devbox globally..."
	@devbox global install 2>/dev/null || devbox global update
