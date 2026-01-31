# ==============================================================================
# Dotfiles Root Makefile
# ==============================================================================
# This Makefile orchestrates all dotfiles operations:
# - Deployment: Delegated to home/Makefile
# - Package management: Homebrew and Devbox (handled here)
# - System configuration: Delegated to home/Makefile

.PHONY: help
help:
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "For deployment-specific targets: make -C home help"


# ========================================
# Common Variables
# ========================================
SHELL := /bin/bash
ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOST  := $(shell hostname -s)
OSNAME := $(shell uname -s)

# Brewfile locations
BREWFILE          := $(ROOT)/.Brewfile
HOST_BREWFILE     := $(ROOT)/hosts/$(HOST).Brewfile
LOCAL_BREWFILE    := $(ROOT)/.Brewfile.local


# ========================================
# Delegated Targets (home/Makefile)
# ========================================

.PHONY: deploy
deploy:  ## Deploy dotfiles
	$(MAKE) -C home deploy

.PHONY: deploy/dry-run
deploy/dry-run:  ## Preview deployment without making changes
	$(MAKE) -C home deploy/dry-run

.PHONY: validate-partial-links
validate-partial-links:  ## Validate PARTIAL_LINKS configuration
	$(MAKE) -C home validate-partial-links

.PHONY: migrate-top-symlink-to-real
migrate-top-symlink-to-real:  ## [Plan A] Migrate TOP from symlink to real directory
	$(MAKE) -C home migrate-top-symlink-to-real

.PHONY: migrate-add-partial-link
migrate-add-partial-link:  ## [Plan B] Add path to PARTIAL_LINKS (real dir -> symlink)
	$(MAKE) -C home migrate-add-partial-link path=$(path)

.PHONY: migrate-remove-partial-link
migrate-remove-partial-link:  ## [Plan C] Remove path from PARTIAL_LINKS (symlink -> real dir)
	$(MAKE) -C home migrate-remove-partial-link path=$(path)

.PHONY: vim
vim:  ## Install vim plug-ins
	$(MAKE) -C home vim

.PHONY: fish
fish:  ## Install fish plug-ins
	$(MAKE) -C home fish

.PHONY: mac-defaults
mac-defaults:  ## Setup macOS settings
	$(MAKE) -C home mac-defaults

.PHONY: pmset-settings
pmset-settings:  ## Setup power management settings
	$(MAKE) -C home pmset-settings


# ========================================
# Initialization
# ========================================

.PHONY: init
init: deploy devbox-install devbox-global-install homebrew  ## Initialize environment
	$(MAKE) -C home vim fish mac-defaults pmset-settings
	$(MAKE) claude-mcp


# ========================================
# Status & Health Checks
# ========================================

.PHONY: status
status:  ## Quick environment status check
	@echo "=== Quick Status Check ==="
	@echo ""
	@echo "--- Git ---"
	@git status --short || echo "Clean"
	@echo ""
	@echo "--- Broken Symlinks ---"
	@broken=$$(find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" | wc -l | tr -d ' '); \
	if [ $$broken -eq 0 ]; then \
		echo "None"; \
	else \
		echo "$$broken found (run 'make doctor' for details)"; \
	fi
	@echo ""
	@echo "--- Packages ---"
	@echo "Run 'make packages/status' for details"
	@echo ""
	@echo "For comprehensive check: make doctor"

.PHONY: doctor
doctor:  ## Run comprehensive environment health checks
	@echo "========================================"
	@echo "  Dotfiles Environment Health Check"
	@echo "========================================"
	@echo ""
	@echo "=== 1. Repository Status ==="
	@git status --short
	@if git status --short | grep -q '^'; then \
		echo "Uncommitted changes found"; \
	else \
		echo "Repository clean"; \
	fi
	@echo ""
	@echo "=== 2. Deployment Verification ==="
	@echo "Checking if all managed files are deployed..."
	@$(MAKE) -C home --no-print-directory doctor/deployment
	@echo ""
	@echo "=== 3. Symlink Integrity ==="
	@$(MAKE) -C home --no-print-directory doctor/symlinks
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

.PHONY: doctor/tools
doctor/tools:  ## Verify essential tools are available
	@echo "Checking essential tools..."
	@missing=0; \
	for tool in make git fish zsh brew devbox vim tmux; do \
		if command -v $$tool > /dev/null 2>&1; then \
			version=$$($$tool --version 2>&1 | head -1 | cut -d' ' -f1-3); \
			echo "$$tool ($$version)"; \
		else \
			echo "$$tool NOT FOUND"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -gt 0 ]; then \
		echo ""; \
		echo "$$missing tools missing. Run 'make init' to install."; \
	fi

.PHONY: doctor/drift
doctor/drift:  ## Detect deployment drift (files in HOME not in repo)
	@echo "Checking for untracked dotfiles in HOME..."
	@untracked=0; \
	for file in $(HOME)/.??*; do \
		basename=$$(basename $$file); \
		if [ -f "$$file" ] || [ -d "$$file" ]; then \
			if [ ! -e "$(ROOT)/home/$$basename" ]; then \
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
		echo "No untracked dotfiles"; \
	else \
		echo ""; \
		echo "Found $$untracked untracked dotfiles in HOME"; \
		echo "Consider adding to dotfiles repo if needed"; \
	fi

.PHONY: doctor/ssh
doctor/ssh:  ## Check SSH configuration and permissions
	@echo "Checking SSH configuration..."
	@if [ -d ~/.ssh ]; then \
		echo "~/.ssh exists"; \
		perms=$$(stat -f "%Op" ~/.ssh 2>/dev/null || stat -c "%a" ~/.ssh 2>/dev/null); \
		if [ "$$perms" = "40700" ] || [ "$$perms" = "700" ]; then \
			echo "~/.ssh permissions correct (700)"; \
		else \
			echo "~/.ssh permissions incorrect ($$perms, should be 700)"; \
		fi; \
		\
		if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then \
			echo "SSH keys found"; \
		else \
			echo "No SSH keys found"; \
		fi; \
	else \
		echo "~/.ssh does not exist"; \
	fi


# ==========================================
# Homebrew Bundle Operations
# ==========================================

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
	@echo "Devbox cleanup complete"

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
		echo "Config exists"; \
	else \
		echo "Config missing"; \
	fi
	@echo "Packages: $$(devbox global list 2>/dev/null | grep -c '' || true)"

.PHONY: packages/outdated
packages/outdated:  ## Show outdated packages with details
	@echo "=== Outdated Packages ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated --greedy --verbose || echo "All up to date"
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


# ==========================================
# Devbox Management
# ==========================================

.PHONY: devbox-install
devbox-install:  ## Install Devbox package manager
	@echo "Installing Devbox..."
	curl -fsSL https://get.jetify.com/devbox | bash

.PHONY: devbox-global-install
devbox-global-install:  ## Install global Devbox packages
	@echo "Installing Devbox globally..."
	@devbox global install 2>/dev/null || devbox global update


# ==========================================
# AI Tools Configuration
# ==========================================

.PHONY: claude-mcp
claude-mcp:  ## Setup Claude Code MCP servers
	@echo "Setting up Claude Code MCP servers..."
	@if command -v claude >/dev/null 2>&1; then \
		claude mcp add --scope user playwright npx @playwright/mcp@latest 2>/dev/null || true; \
		echo "MCP servers configured"; \
		claude mcp list; \
	else \
		echo "claude command not found. Install via: devbox global add claude-code"; \
	fi


# ==========================================
# iTerm2 Profiles
# ==========================================

.PHONY: iterm2-profiles
iterm2-profiles:  ## Deploy iTerm2 Dynamic Profiles
ifeq  "$(OSNAME)" "Darwin"
	@echo "Deploying iTerm2 Dynamic Profiles..."
	@mkdir -p "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles"
	@cp -v apps/iterm2/profiles/*.json \
		"$(HOME)/Library/Application Support/iTerm2/DynamicProfiles/"
	@echo "iTerm2 profiles deployed. Changes will be loaded automatically."
endif


# ==========================================
# Security Scanning
# ==========================================

.PHONY: security-scan
security-scan:  ## Run full gitleaks scan of repository history
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "Scanning repository for secrets..."; \
		gitleaks detect --verbose --report-path=gitleaks-report.json --report-format=json; \
		if [ -f gitleaks-report.json ]; then \
			echo ""; \
			echo "Report saved to: gitleaks-report.json"; \
			echo "Review the report and remediate any findings."; \
		fi; \
	else \
		echo "gitleaks not installed. Run: devbox global add gitleaks@latest"; \
		exit 1; \
	fi

.PHONY: security-protect
security-protect:  ## Scan staged changes before commit
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "Scanning staged changes for secrets..."; \
		gitleaks protect --verbose --staged; \
	else \
		echo "gitleaks not installed. Run: devbox global add gitleaks@latest"; \
		exit 1; \
	fi

.PHONY: security-install
security-install:  ## Install security tools and hooks
	@echo "Installing security tools..."
	@if ! command -v gitleaks >/dev/null 2>&1; then \
		echo "Installing gitleaks..."; \
		devbox global add gitleaks@latest; \
	else \
		echo "gitleaks already installed"; \
	fi
	@echo "Installing pre-commit hook..."
	@if [ ! -f .git/hooks/pre-commit ]; then \
		echo "#!/bin/sh" > .git/hooks/pre-commit; \
		echo "# Pre-commit hook to detect secrets" >> .git/hooks/pre-commit; \
		echo "gitleaks protect --verbose --redact --staged" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Pre-commit hook installed"; \
	else \
		echo "Pre-commit hook already exists"; \
	fi
	@echo ""
	@echo "Security setup complete!"
	@echo "  - Run 'make security-scan' to scan entire repository"
	@echo "  - Run 'make security-protect' to scan staged changes"
	@echo "  - Pre-commit hook will automatically check commits"


# ==============================================================================
# Git Hooks Management (Global)
# ==============================================================================

.PHONY: git-hooks-setup
git-hooks-setup:  ## Setup global git hooks (configure + update existing repos)
	@echo "Setting up global Git hooks..."
	@echo ""
	@if [ ! -d home/.config/git/template/hooks ]; then \
		echo "Error: home/.config/git/template/hooks not found"; \
		echo "   Run 'make deploy' first to setup directory structure"; \
		exit 1; \
	fi
	@echo "Template directory verified"
	@echo ""
	@echo "Configuring git init.templateDir..."
	@git config --global init.templateDir ~/.config/git/template
	@echo "Git config updated"
	@echo ""
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "gitleaks found"; \
	else \
		echo "Warning: gitleaks not found"; \
		echo "   Install: devbox global add gitleaks@latest"; \
		echo ""; \
	fi
	@echo "Updating existing repositories..."
	@echo ""
	@$(HOME)/bin/git-hooks-update || true
	@echo ""
	@echo "Global git hooks setup complete!"
	@echo ""
	@echo "What's configured:"
	@echo "  - New repositories: Hooks auto-installed on git init/clone"
	@echo "  - Existing repos: Updated with pre-commit hook"
	@echo "  - Security: gitleaks runs on every commit"
	@echo "  - Compatibility: Works with Husky, pre-commit framework, etc."
	@echo ""
	@echo "See home/.config/git/hooks/README.md for details"

.PHONY: git-hooks-update
git-hooks-update:  ## Update existing repositories with global hooks
	@if [ ! -x $(HOME)/bin/git-hooks-update ]; then \
		echo "Error: git-hooks-update script not found or not executable"; \
		echo "   Run 'make deploy' first"; \
		exit 1; \
	fi
	@$(HOME)/bin/git-hooks-update


# ==========================================
# Testing
# ==========================================

.PHONY: test
test:  ## Run deployment tests in sandbox
	$(MAKE) -C home test

.PHONY: test/quick
test/quick:  ## Quick sanity check
	$(MAKE) -C home test/quick
