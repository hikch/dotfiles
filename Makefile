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

# Migration backup directory for PARTIAL_LINKS conversion
MIGRATION_BACKUP_DIR := /tmp/dotfiles-migration-$(shell date +%Y%m%d_%H%M%S)


.PHONY: init
init: deploy devbox-install devbox-global-install homebrew fish mac-defaults pmset-settings ## Initialize.

# ========================================
# PARTIAL_LINKS Migration
# ========================================
# Migrates parent directories from full symlinks to real directories
# when converting from full-directory symlinks to selective PARTIAL_LINKS

.PHONY: deploy/migrate-partial-tops
deploy/migrate-partial-tops:
	@echo "=== Migrating PARTIAL_TOPS: symlink -> real directory ==="
	@$(foreach top,$(PARTIAL_TOPS), \
		echo "Processing $(top)..."; \
		if [ -L $(HOME)/$(top) ]; then \
			echo "  $(HOME)/$(top) is a symlink, migrating..."; \
			mkdir -p $(MIGRATION_BACKUP_DIR); \
			echo "  Backing up non-PARTIAL_LINKS items from repo/$(top)/..."; \
			$(MAKE) --no-print-directory _migrate_copy_unlinked TOP=$(top) BACKUP=$(MIGRATION_BACKUP_DIR)/$(top); \
			echo "  Removing old symlink $(HOME)/$(top)"; \
			rm $(HOME)/$(top); \
			echo "  Creating real directory $(HOME)/$(top)"; \
			mkdir -p $(HOME)/$(top); \
			echo "  Restoring non-PARTIAL_LINKS items to $(HOME)/$(top)/..."; \
			if [ -d $(MIGRATION_BACKUP_DIR)/$(top) ]; then \
				cp -a $(MIGRATION_BACKUP_DIR)/$(top)/. $(HOME)/$(top)/; \
			fi; \
		elif [ ! -e $(HOME)/$(top) ]; then \
			echo "  Creating $(HOME)/$(top) as real directory"; \
			mkdir -p $(HOME)/$(top); \
		else \
			echo "  $(HOME)/$(top) already exists as real directory"; \
		fi;)
	@if [ -d $(MIGRATION_BACKUP_DIR) ]; then \
		echo ""; \
		echo "Migration complete. Backup kept at: $(MIGRATION_BACKUP_DIR)"; \
	fi

.PHONY: _migrate_copy_unlinked
_migrate_copy_unlinked:
	@if [ -d $(DOTPATH)/$(TOP) ]; then \
		mkdir -p $(BACKUP); \
		for item in $(DOTPATH)/$(TOP)/*; do \
			if [ ! -e "$$item" ]; then continue; fi; \
			basename=$$(basename $$item); \
			is_linked=0; \
			for link in $(PARTIAL_LINKS); do \
				if [ "$$link" = "$(TOP)/$$basename" ] || echo "$$link" | grep -q "^$(TOP)/$$basename/"; then \
					is_linked=1; \
					break; \
				fi; \
			done; \
			if [ $$is_linked -eq 0 ]; then \
				echo "    Copying $$basename (not in PARTIAL_LINKS)"; \
				cp -a $$item $(BACKUP)/; \
			else \
				echo "    Skipping $$basename (in PARTIAL_LINKS)"; \
			fi; \
		done; \
	fi

.PHONY: deploy
deploy: deploy/migrate-partial-tops  ## Deploy dotfiles.
	@# Note: .config migration is now handled by deploy/migrate-partial-tops
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
status:  ## Quick environment status check
	@echo "=== Quick Status Check ==="
	@echo ""
	@echo "--- Git ---"
	@git status --short || echo "✓ Clean"
	@echo ""
	@echo "--- Broken Symlinks ---"
	@broken=$$(find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" | wc -l | tr -d ' '); \
	if [ $$broken -eq 0 ]; then \
		echo "✓ None"; \
	else \
		echo "⚠️  $$broken found (run 'make doctor' for details)"; \
	fi
	@echo ""
	@echo "--- Packages ---"
	@echo "Run 'make packages/status' for details"
	@echo ""
	@echo "For comprehensive check: make doctor"


# ========================================
# Health Checks & Diagnostics
# ========================================

.PHONY: doctor
doctor:  ## Run comprehensive environment health checks
	@echo "========================================"
	@echo "  Dotfiles Environment Health Check"
	@echo "========================================"
	@echo ""
	@echo "=== 1. Repository Status ==="
	@git status --short
	@if git status --short | grep -q '^'; then \
		echo "⚠️  Uncommitted changes found"; \
	else \
		echo "✓ Repository clean"; \
	fi
	@echo ""
	@echo "=== 2. Deployment Verification ==="
	@echo "Checking if all managed files are deployed..."
	@$(MAKE) --no-print-directory doctor/deployment
	@echo ""
	@echo "=== 3. Symlink Integrity ==="
	@$(MAKE) --no-print-directory doctor/symlinks
	@echo ""
	@echo "=== 4. Tool Availability ==="
	@$(MAKE) --no-print-directory doctor/tools
	@echo ""
	@echo "=== 5. Package Health ==="
	@$(MAKE) --no-print-directory packages/doctor
	@echo ""
	@echo "=== 6. Shell Environment ==="
	@echo "Current shell: $$SHELL"
	@echo "Fish installed: $$(which fish || echo 'NOT FOUND')"
	@echo "Zsh installed: $$(which zsh || echo 'NOT FOUND')"
	@echo ""
	@echo "========================================"
	@echo "  Health Check Complete"
	@echo "========================================"

.PHONY: doctor/deployment
doctor/deployment:  ## Verify all managed files are deployed
	@echo "Checking deployment status..."
	@deployed=0; missing=0; \
	for file in $(DOTFILES); do \
		if [ -L "$(HOME)/$$file" ]; then \
			target=$$(readlink "$(HOME)/$$file"); \
			expected="$(DOTPATH)/$$file"; \
			if [ "$$target" = "$$expected" ]; then \
				deployed=$$((deployed + 1)); \
			else \
				echo "⚠️  $$file -> wrong target ($$target instead of $$expected)"; \
				missing=$$((missing + 1)); \
			fi; \
		else \
			echo "✗ $$file not deployed"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	echo "✓ $$deployed files deployed correctly"; \
	if [ $$missing -gt 0 ]; then \
		echo "⚠️  $$missing files missing or incorrect"; \
		echo "Run 'make deploy' to fix"; \
	fi
	@echo ""
	@echo "Checking partial links..."
	@for path in $(PARTIAL_LINKS); do \
		if [ -L "$(HOME)/$$path" ]; then \
			target=$$(readlink "$(HOME)/$$path"); \
			expected="$(DOTPATH)/$$path"; \
			if [ "$$target" = "$$expected" ]; then \
				echo "✓ $$path"; \
			else \
				echo "⚠️  $$path -> wrong target"; \
			fi; \
		else \
			echo "✗ $$path not deployed"; \
		fi; \
	done

.PHONY: doctor/symlinks
doctor/symlinks:  ## Check symlink integrity
	@echo "Checking for broken symlinks in HOME..."
	@broken=$$(find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" | wc -l | tr -d ' '); \
	if [ $$broken -eq 0 ]; then \
		echo "✓ No broken symlinks"; \
	else \
		echo "⚠️  $$broken broken symlinks found:"; \
		find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash"; \
	fi
	@echo ""
	@echo "Checking symlinks point to this repo..."
	@wrong=0; \
	for link in $$(find $(HOME) -maxdepth 1 -type l 2>/dev/null); do \
		target=$$(readlink "$$link"); \
		if echo "$$target" | grep -q "$(DOTPATH)"; then \
			: ; \
		elif echo "$$target" | grep -q "dotfiles"; then \
			echo "⚠️  $$(basename $$link) -> different dotfiles repo ($$target)"; \
			wrong=$$((wrong + 1)); \
		fi; \
	done; \
	if [ $$wrong -eq 0 ]; then \
		echo "✓ All dotfiles symlinks point to this repo"; \
	else \
		echo "⚠️  $$wrong symlinks point to other dotfiles repos"; \
	fi

.PHONY: doctor/tools
doctor/tools:  ## Verify essential tools are available
	@echo "Checking essential tools..."
	@missing=0; \
	for tool in make git fish zsh brew devbox vim tmux; do \
		if command -v $$tool > /dev/null 2>&1; then \
			version=$$($$tool --version 2>&1 | head -1 | cut -d' ' -f1-3); \
			echo "✓ $$tool ($$version)"; \
		else \
			echo "✗ $$tool NOT FOUND"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -gt 0 ]; then \
		echo ""; \
		echo "⚠️  $$missing tools missing. Run 'make init' to install."; \
	fi

.PHONY: doctor/drift
doctor/drift:  ## Detect deployment drift (files in HOME not in repo)
	@echo "Checking for untracked dotfiles in HOME..."
	@untracked=0; \
	for file in $(HOME)/.??*; do \
		basename=$$(basename $$file); \
		if [ -f "$$file" ] || [ -d "$$file" ]; then \
			if [ ! -e "$(DOTPATH)/$$basename" ]; then \
				case "$$basename" in \
					.Trash|.DS_Store|.CFUserTextEncoding|.cups) \
						: ;; \
					*) \
						echo "  $$basename"; \
						untracked=$$((untracked + 1)); \
						;; \
				esac; \
			fi; \
		fi; \
	done; \
	if [ $$untracked -eq 0 ]; then \
		echo "✓ No untracked dotfiles"; \
	else \
		echo ""; \
		echo "Found $$untracked untracked dotfiles in HOME"; \
		echo "Consider adding to dotfiles repo if needed"; \
	fi

.PHONY: doctor/ssh
doctor/ssh:  ## Check SSH configuration and permissions
	@echo "Checking SSH configuration..."
	@if [ -d ~/.ssh ]; then \
		echo "✓ ~/.ssh exists"; \
		perms=$$(stat -f "%Op" ~/.ssh 2>/dev/null || stat -c "%a" ~/.ssh 2>/dev/null); \
		if [ "$$perms" = "40700" ] || [ "$$perms" = "700" ]; then \
			echo "✓ ~/.ssh permissions correct (700)"; \
		else \
			echo "⚠️  ~/.ssh permissions incorrect ($$perms, should be 700)"; \
		fi; \
		\
		if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then \
			echo "✓ SSH keys found"; \
		else \
			echo "⚠️  No SSH keys found"; \
		fi; \
	else \
		echo "✗ ~/.ssh does not exist"; \
	fi


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

.PHONY: devbox/cleanup
devbox/cleanup:  ## Remove Devbox cache and rebuild
	@echo "=== Devbox Cleanup ==="
	@echo "This will remove cache and reinstall packages"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@devbox global run -- sh -c "devbox cache clean" || true
	@devbox global install
	@echo "✓ Devbox cleanup complete"

.PHONY: packages/cleanup
packages/cleanup:  ## Clean up unused packages
	@echo "=== Homebrew Cleanup ==="
	@$(MAKE) brew/cleanup
	@echo ""
	@echo "To clean Devbox cache: make devbox/cleanup"

.PHONY: packages/doctor
packages/doctor:  ## Run health checks on package managers
	@echo "=== Package Manager Health Check ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew doctor || true
	@echo ""
	@echo "--- Devbox ---"
	@echo "Version: $$(devbox version)"
	@echo "Global path: $$(devbox global path)"
	@if [ -f "$$(devbox global path)/devbox.json" ]; then \
		echo "✓ Config exists"; \
	else \
		echo "✗ Config missing"; \
	fi
	@echo "Packages: $$(devbox global list 2>/dev/null | grep -c '✓' || true)"

.PHONY: packages/outdated
packages/outdated:  ## Show outdated packages with details
	@echo "=== Outdated Packages ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated --greedy --verbose || echo "✓ All up to date"
	@echo ""
	@echo "--- Devbox ---"
	@echo "Devbox uses latest nixpkgs. Run 'devbox global update' to update."

.PHONY: packages/search
packages/search:  ## Search for package (PKG=name)
	@test -n "$(PKG)" || (echo "Usage: make packages/search PKG=jq"; exit 1)
	@echo "=== Homebrew ==="
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew search $(PKG) | head -20
	@echo ""
	@echo "=== Devbox ==="
	@devbox search $(PKG) 2>/dev/null | head -20 || echo "Install devbox to search"

.PHONY: packages/add
packages/add:  ## Add package (TYPE=cli|gui PKG=name)
	@test -n "$(PKG)" || (echo "Usage: make packages/add PKG=jq TYPE=cli"; exit 1)
	@if [ "$(TYPE)" = "gui" ]; then \
		$(MAKE) brew/cask-add NAME=$(PKG); \
	elif [ "$(TYPE)" = "cli" ]; then \
		echo "Run: devbox global add $(PKG)"; \
		echo "Then: git add .local/share/devbox/global/default/devbox.json"; \
	else \
		echo "TYPE must be 'cli' or 'gui'"; exit 1; \
	fi


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
