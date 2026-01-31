# ==============================================================================
# Dotfiles Deployment Makefile
# ==============================================================================
# This Makefile handles deployment of dotfiles from home/ to $HOME.
# Package management (Homebrew, Devbox) is handled by the parent Makefile.

.PHONY: help
help:
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
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

# Migration backup directory for PARTIAL_LINKS conversion (overridable)
MIGRATION_BACKUP_DIR ?= /tmp/dotfiles-migration-$(shell date +%Y%m%d_%H%M%S)


# ========================================
# PARTIAL_LINKS Migration Targets
# ========================================

# ----------------------------------------
# Plan A: One-time rescue migration (TOP symlink -> real directory)
# ----------------------------------------
# Purpose: Clean up legacy full-symlink management of .config/.local
# When to use: Only when migrating from old symlink structure
# Destructive: Yes (requires backup)
# Frequency: One-time only

.PHONY: migrate-top-symlink-to-real
migrate-top-symlink-to-real:  ## [Plan A] Migrate TOP from symlink to real directory (one-time rescue)
	@echo "=== Migrating PARTIAL_TOPS: symlink -> real directory ==="
	@$(foreach top,$(PARTIAL_TOPS), \
		echo "Processing $(top)..."; \
		if [ -L $(HOME)/$(top) ]; then \
			echo "  $(HOME)/$(top) is a symlink, migrating..."; \
			mkdir -p $(MIGRATION_BACKUP_DIR)/top-migration; \
			echo "  Backing up non-PARTIAL_LINKS items from repo/$(top)/..."; \
			$(MAKE) --no-print-directory _migrate_copy_unlinked TOP=$(top) BACKUP=$(MIGRATION_BACKUP_DIR)/top-migration/$(top); \
			echo "  Removing old symlink $(HOME)/$(top)"; \
			rm $(HOME)/$(top); \
			echo "  Creating real directory $(HOME)/$(top)"; \
			mkdir -p $(HOME)/$(top); \
			echo "  Restoring non-PARTIAL_LINKS items to $(HOME)/$(top)/..."; \
			if [ -d $(MIGRATION_BACKUP_DIR)/top-migration/$(top) ]; then \
				rsync -a $(MIGRATION_BACKUP_DIR)/top-migration/$(top)/ $(HOME)/$(top)/; \
			fi; \
			echo "  Cleaning up non-PARTIAL_LINKS items from repo/$(top)/..."; \
			$(MAKE) --no-print-directory _migrate_remove_unlinked TOP=$(top) BACKUP=$(MIGRATION_BACKUP_DIR)/top-migration/$(top); \
		elif [ -f $(HOME)/$(top) ]; then \
			echo "  ERROR: $(HOME)/$(top) exists as a file, expected directory or symlink"; \
			exit 1; \
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
		find $(DOTPATH)/$(TOP) -mindepth 1 -maxdepth 1 | while IFS= read -r item; do \
			basename=$$(basename "$$item"); \
			is_linked=0; \
			for link in $(PARTIAL_LINKS); do \
				if [ "$$link" = "$(TOP)/$$basename" ] || echo "$$link/" | grep -qF "$(TOP)/$$basename/"; then \
					is_linked=1; \
					break; \
				fi; \
			done; \
			if [ $$is_linked -eq 0 ]; then \
				echo "    Copying $$basename (not in PARTIAL_LINKS)"; \
				rsync -a "$$item" "$(BACKUP)/"; \
			else \
				echo "    Skipping $$basename (in PARTIAL_LINKS)"; \
			fi; \
		done; \
	fi

.PHONY: _migrate_remove_unlinked
_migrate_remove_unlinked:
	@if [ ! -d $(BACKUP) ]; then \
		echo "    WARNING: Backup directory $(BACKUP) not found"; \
		echo "    Skipping cleanup for safety (files NOT removed from repository)"; \
		exit 0; \
	fi
	@if [ -z "$$(ls -A $(BACKUP) 2>/dev/null)" ]; then \
		echo "    Backup directory is empty, nothing to clean up"; \
		exit 0; \
	fi
	@if [ -d $(DOTPATH)/$(TOP) ]; then \
		removed_count=0; \
		find $(DOTPATH)/$(TOP) -mindepth 1 -maxdepth 1 | while IFS= read -r item; do \
			basename=$$(basename "$$item"); \
			is_linked=0; \
			for link in $(PARTIAL_LINKS); do \
				if [ "$$link" = "$(TOP)/$$basename" ] || echo "$$link/" | grep -qF "$(TOP)/$$basename/"; then \
					is_linked=1; \
					break; \
				fi; \
			done; \
			if [ $$is_linked -eq 0 ]; then \
				echo "    Removing $$basename (not in PARTIAL_LINKS, backup confirmed)"; \
				rm -rf "$$item"; \
				removed_count=$$((removed_count + 1)); \
			else \
				echo "    Keeping $$basename (in PARTIAL_LINKS)"; \
			fi; \
		done; \
	fi

# ----------------------------------------
# Plan B: Add item to PARTIAL_LINKS (real directory -> symlink)
# ----------------------------------------
# Purpose: Convert existing real directory to symlink management
# When to use: After adding new path to PARTIAL_LINKS file
# Destructive: Yes (requires manual review of backup)
# Usage: make migrate-add-partial-link path=.config/uv

.PHONY: migrate-add-partial-link
migrate-add-partial-link:  ## [Plan B] Add path to PARTIAL_LINKS (real dir -> symlink)
	@if [ -z "$(path)" ]; then \
		echo "ERROR: path parameter required"; \
		echo "Usage: make migrate-add-partial-link path=.config/uv"; \
		exit 1; \
	fi
	@echo "=== Validating path parameter ==="
	@if echo "$(path)" | grep -qE '^/'; then \
		echo "ERROR: Absolute paths are not allowed"; \
		echo "  Provided: $(path)"; \
		echo "  Expected: Relative path starting with '.' (e.g., .config/uv)"; \
		exit 1; \
	fi
	@if echo "$(path)" | grep -qE '(^|/)\.\.(/|$$)'; then \
		echo "ERROR: Path cannot contain '..' components"; \
		echo "  Provided: $(path)"; \
		echo "  Reason: '..' could escape repository scope and delete parent directories"; \
		exit 1; \
	fi
	@if ! echo "$(path)" | grep -qE '^\.[^/]'; then \
		echo "ERROR: Path must start with '.' (dotfile convention)"; \
		echo "  Provided: $(path)"; \
		echo "  Expected: Path like .config/foo, .local/bar, etc."; \
		exit 1; \
	fi
	@echo "Path validation passed"
	@echo "=== Adding $(path) to PARTIAL_LINKS management ==="
	@if [ ! -e $(HOME)/$(path) ]; then \
		echo "$(HOME)/$(path) does not exist, creating symlink directly"; \
		if [ ! -d $(DOTPATH)/$(path) ]; then \
			echo "-> Creating empty repository directory $(DOTPATH)/$(path)"; \
			mkdir -p $(DOTPATH)/$(path); \
		fi; \
		mkdir -p $(HOME)/$$(dirname $(path)); \
		ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path); \
		echo "Done. Add content to $(DOTPATH)/$(path) as needed"; \
		exit 0; \
	fi
	@if [ -L $(HOME)/$(path) ]; then \
		echo "ERROR: $(HOME)/$(path) is already a symlink"; \
		echo "Current target: $$(readlink $(HOME)/$(path))"; \
		exit 1; \
	fi
	@mkdir -p $(MIGRATION_BACKUP_DIR)/add; \
	backup_path="$(MIGRATION_BACKUP_DIR)/add/$(path)"; \
	if [ -d $(HOME)/$(path) ]; then \
		echo "-> Backing up directory $(HOME)/$(path) to $$backup_path"; \
		mkdir -p "$$backup_path"; \
		rsync -a $(HOME)/$(path)/ $$backup_path/; \
		echo "-> Removing real directory $(HOME)/$(path)"; \
		rm -rf $(HOME)/$(path); \
		if [ ! -d $(DOTPATH)/$(path) ]; then \
			echo "-> Creating empty repository directory $(DOTPATH)/$(path)"; \
			mkdir -p $(DOTPATH)/$(path); \
		fi; \
	else \
		echo "-> Backing up file $(HOME)/$(path) to $$backup_path"; \
		mkdir -p "$$(dirname $$backup_path)"; \
		cp -p $(HOME)/$(path) $$backup_path; \
		echo "-> Removing real file $(HOME)/$(path)"; \
		rm -f $(HOME)/$(path); \
		if [ ! -f $(DOTPATH)/$(path) ]; then \
			echo "-> Copying file to repository $(DOTPATH)/$(path)"; \
			mkdir -p $(DOTPATH)/$$(dirname $(path)); \
			cp -p $$backup_path $(DOTPATH)/$(path); \
		fi; \
	fi; \
	echo "-> Creating symlink $(HOME)/$(path) -> $(DOTPATH)/$(path)"; \
	mkdir -p $(HOME)/$$(dirname $(path)); \
	ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path); \
	echo ""; \
	echo "Migration complete"; \
	echo ""; \
	echo "Backup location: $$backup_path"; \
	echo ""; \
	echo "Next steps:"; \
	echo "  1. Review backup and decide what to keep"; \
	echo "  2. Manually copy desired content to $(DOTPATH)/$(path)"; \
	echo "  3. Git add/commit configuration files you want to track"; \
	echo "  4. Delete backup when satisfied: rm -rf $(MIGRATION_BACKUP_DIR)"

# ----------------------------------------
# Plan C: Remove item from PARTIAL_LINKS (symlink -> real directory)
# ----------------------------------------
# Purpose: Stop managing path as symlink, convert back to real directory
# When to use: After removing path from PARTIAL_LINKS file
# Destructive: No (preserves repo content)
# Usage: make migrate-remove-partial-link path=.config/git

.PHONY: migrate-remove-partial-link
migrate-remove-partial-link:  ## [Plan C] Remove path from PARTIAL_LINKS (symlink -> real dir)
	@if [ -z "$(path)" ]; then \
		echo "ERROR: path parameter required"; \
		echo "Usage: make migrate-remove-partial-link path=.config/git"; \
		exit 1; \
	fi
	@echo "=== Validating path parameter ==="
	@if echo "$(path)" | grep -qE '^/'; then \
		echo "ERROR: Absolute paths are not allowed"; \
		echo "  Provided: $(path)"; \
		echo "  Expected: Relative path starting with '.' (e.g., .config/git)"; \
		exit 1; \
	fi
	@if echo "$(path)" | grep -qE '(^|/)\.\.(/|$$)'; then \
		echo "ERROR: Path cannot contain '..' components"; \
		echo "  Provided: $(path)"; \
		echo "  Reason: '..' could escape repository scope and delete parent directories"; \
		exit 1; \
	fi
	@if ! echo "$(path)" | grep -qE '^\.[^/]'; then \
		echo "ERROR: Path must start with '.' (dotfile convention)"; \
		echo "  Provided: $(path)"; \
		echo "  Expected: Path like .config/foo, .local/bar, etc."; \
		exit 1; \
	fi
	@echo "Path validation passed"
	@echo "=== Removing $(path) from PARTIAL_LINKS management ==="
	@if [ ! -e $(HOME)/$(path) ]; then \
		echo "$(HOME)/$(path) does not exist, nothing to migrate"; \
		exit 0; \
	fi
	@if [ ! -L $(HOME)/$(path) ]; then \
		echo "ERROR: $(HOME)/$(path) is not a symlink"; \
		echo "It's already a real directory, no migration needed"; \
		exit 1; \
	fi
	@link_target=$$(readlink $(HOME)/$(path)); \
	echo "Current symlink: $(HOME)/$(path) -> $$link_target"; \
	@mkdir -p $(MIGRATION_BACKUP_DIR)/remove; \
	backup_dir="$(MIGRATION_BACKUP_DIR)/remove/$(path)"; \
	echo "-> Backing up repo content to $$backup_dir"; \
	mkdir -p "$$backup_dir"; \
	if [ -d $(DOTPATH)/$(path) ]; then \
		rsync -a $(DOTPATH)/$(path)/ $$backup_dir/; \
	fi; \
	echo "-> Removing symlink $(HOME)/$(path)"; \
	rm $(HOME)/$(path); \
	echo "-> Creating real directory and copying content from repo"; \
	mkdir -p $(HOME)/$(path); \
	if [ -d $(DOTPATH)/$(path) ]; then \
		rsync -a $(DOTPATH)/$(path)/ $(HOME)/$(path)/; \
	fi; \
	echo ""; \
	echo "Migration complete"; \
	echo ""; \
	echo "Backup location: $$backup_dir"; \
	echo ""; \
	echo "Next steps:"; \
	echo "  1. Repository content preserved at $(DOTPATH)/$(path)"; \
	echo "  2. Add $(path) to .gitignore if you don't want to track it"; \
	echo "  3. Or manually remove from repo: rm -rf $(DOTPATH)/$(path)"; \
	echo "  4. Delete backup when satisfied: rm -rf $(MIGRATION_BACKUP_DIR)"

# ----------------------------------------
# Validation: Pre-deploy safety checks
# ----------------------------------------

.PHONY: validate-partial-links
validate-partial-links:  ## Validate PARTIAL_LINKS configuration before deploy
	@echo "=== Validating PARTIAL_LINKS configuration ==="
	@error_count=0; \
	for path in $(PARTIAL_LINKS); do \
		if echo "$$path" | grep -qE '(\.\./|^/)'; then \
			echo "ERROR: Invalid path in PARTIAL_LINKS: $$path"; \
			echo "   Paths cannot contain '..' or start with '/'"; \
			error_count=$$((error_count + 1)); \
		fi; \
		if [ ! -e $(DOTPATH)/$$path ]; then \
			echo "WARNING: $(DOTPATH)/$$path does not exist in repository"; \
		fi; \
		if [ -e $(HOME)/$$path ] && [ ! -L $(HOME)/$$path ]; then \
			echo "WARNING: $(HOME)/$$path exists as real file/dir"; \
			echo "   Run: make migrate-add-partial-link path=$$path"; \
		fi; \
	done; \
	if [ $$error_count -gt 0 ]; then \
		echo ""; \
		echo "Validation failed with $$error_count error(s)"; \
		exit 1; \
	fi; \
	echo "Validation complete"

.PHONY: deploy
deploy: validate-partial-links  ## Deploy dotfiles
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)
	@$(foreach path,$(PARTIAL_LINKS), \
		mkdir -p $(HOME)/$(dir $(path)); \
		if [ -L $(HOME)/$(path) ] || [ ! -e $(HOME)/$(path) ]; then \
			rm -f $(HOME)/$(path); \
			ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path); \
		elif [ -e $(HOME)/$(path) ]; then \
			echo "ERROR: $(HOME)/$(path) exists as real file/dir"; \
			echo "  Run: make migrate-add-partial-link path=$(path)"; \
			exit 1; \
		fi;)
	@if [ -d ~/.ssh ]; then \
		chown $$(id -un):$$(id -gn) ~/.ssh; \
		chmod 0700 ~/.ssh; \
	fi

.PHONY: deploy/dry-run
deploy/dry-run:  ## Preview deployment without making changes
	@echo "=== Deployment Preview ==="
	@echo "Standard symlinks:"
	@$(foreach val, $(DOTFILES), echo "  $(abspath $(val)) -> $(HOME)/$(val)";)
	@echo ""
	@echo "Partial symlinks:"
	@$(foreach path,$(PARTIAL_LINKS), echo "  $(DOTPATH)/$(path) -> $(HOME)/$(path)";)


# ========================================
# Health Checks & Diagnostics
# ========================================

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
				echo "  $$file -> wrong target ($$target instead of $$expected)"; \
				missing=$$((missing + 1)); \
			fi; \
		else \
			echo "  $$file not deployed"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	echo "$$deployed files deployed correctly"; \
	if [ $$missing -gt 0 ]; then \
		echo "$$missing files missing or incorrect"; \
		echo "Run 'make deploy' to fix"; \
	fi
	@echo ""
	@echo "Checking partial links..."
	@for path in $(PARTIAL_LINKS); do \
		if [ -L "$(HOME)/$$path" ]; then \
			target=$$(readlink "$(HOME)/$$path"); \
			expected="$(DOTPATH)/$$path"; \
			if [ "$$target" = "$$expected" ]; then \
				echo "  $$path"; \
			else \
				echo "  $$path -> wrong target"; \
			fi; \
		else \
			echo "  $$path not deployed"; \
		fi; \
	done

.PHONY: doctor/symlinks
doctor/symlinks:  ## Check symlink integrity
	@echo "Checking for broken symlinks in HOME..."
	@broken=$$(find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" | wc -l | tr -d ' '); \
	if [ $$broken -eq 0 ]; then \
		echo "No broken symlinks"; \
	else \
		echo "$$broken broken symlinks found:"; \
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
			echo "  $$(basename $$link) -> different dotfiles repo ($$target)"; \
			wrong=$$((wrong + 1)); \
		fi; \
	done; \
	if [ $$wrong -eq 0 ]; then \
		echo "All dotfiles symlinks point to this repo"; \
	else \
		echo "$$wrong symlinks point to other dotfiles repos"; \
	fi


# ========================================
# Plugin Installation
# ========================================

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


# ========================================
# macOS Settings
# ========================================

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


# ========================================
# Testing
# ========================================

.PHONY: test
test:  ## Run deployment tests in sandbox
	@echo "=== Running deployment tests ==="
	@./tests/test_deploy.sh

.PHONY: test/quick
test/quick:  ## Quick sanity check
	@$(MAKE) deploy/dry-run > /dev/null && echo "dry-run OK"
	@$(MAKE) validate-partial-links > /dev/null && echo "validate OK"
