# Phase 3: Package Management Consolidation

**Priority:** MEDIUM-HIGH
**Estimated Effort:** 1 hour
**Impact:** Complete unified interface for package management

## Current State

### Phase 1 Accomplishments (Already Implemented)

The following commands were added in Phase 1:

```make
packages/install   # Install all packages (Devbox + Homebrew)
packages/update    # Update all packages
packages/status    # Show package status
packages/cleanup   # Clean up unused Homebrew packages
```

## Remaining Gaps

### 1. Incomplete Cleanup
- `packages/cleanup` only handles Homebrew
- No Devbox cleanup implementation
- Devbox doesn't have built-in garbage collection

### 2. Missing Diagnostic Commands
- No `packages/doctor` for health checks
- No `packages/outdated` summary
- No way to verify package integrity

### 3. Limited Add/Remove Workflow
- No `packages/add` wrapper
- Still need to know which package manager to use
- Manual JSON editing for Devbox packages

## Proposed Enhancements

### 1. Implement Devbox Cleanup

Devbox doesn't track which packages are "unused", but we can implement smart cleanup:

```make
.PHONY: devbox/cleanup
devbox/cleanup:  ## Remove Devbox cache and rebuild
	@echo "=== Devbox Cleanup ==="
	@echo "This will:"
	@echo "  1. Remove Devbox cache"
	@echo "  2. Reinstall packages from devbox.json"
	@echo ""
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@devbox global run -- sh -c "devbox cache clean"
	@devbox global install
	@echo "✓ Devbox cleanup complete"

.PHONY: packages/cleanup
packages/cleanup: brew/cleanup devbox/cleanup  ## Clean up unused packages (full)
```

### 2. Add packages/doctor

Comprehensive diagnostics across both package managers:

```make
.PHONY: packages/doctor
packages/doctor:  ## Run health checks on package managers
	@echo "=== Package Manager Health Check ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew doctor || true
	@echo ""
	@echo "--- Devbox ---"
	@echo "Devbox version: $$(devbox version)"
	@echo "Devbox global path: $$(devbox global path)"
	@if [ -f "$$(devbox global path)/devbox.json" ]; then \
		echo "✓ Global config exists"; \
	else \
		echo "✗ Global config missing"; \
	fi
	@echo ""
	@echo "--- Package Counts ---"
	@echo "Homebrew formulae: $$(brew list --formula | wc -l | tr -d ' ')"
	@echo "Homebrew casks: $$(brew list --cask | wc -l | tr -d ' ')"
	@echo "Devbox packages: $$(devbox global list 2>/dev/null | grep -c '✓' || echo 0)"
```

### 3. Enhanced packages/outdated

Better summary of outdated packages:

```make
.PHONY: packages/outdated
packages/outdated:  ## Show outdated packages with details
	@echo "=== Outdated Packages ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated --greedy --verbose || echo "All packages up to date"
	@echo ""
	@echo "--- Devbox ---"
	@echo "Note: Devbox always uses latest versions from nixpkgs"
	@echo "Devbox config: $$(devbox global path)/devbox.json"
	@echo "Run 'devbox global update' to update to latest nixpkgs"
```

### 4. Smart packages/add

Wrapper that intelligently routes to correct package manager:

```make
.PHONY: packages/add
packages/add:  ## Add package (auto-detect type). Usage: make packages/add PKG=name TYPE=cli|gui
	@test -n "$(PKG)" || (echo "PKG is required. Usage: make packages/add PKG=jq TYPE=cli"; exit 1)
	@if [ "$(TYPE)" = "gui" ] || [ "$(TYPE)" = "cask" ]; then \
		echo "Adding GUI app '$(PKG)' via Homebrew..."; \
		$(MAKE) brew/cask-add NAME=$(PKG); \
	elif [ "$(TYPE)" = "cli" ] || [ "$(TYPE)" = "devbox" ]; then \
		echo "Adding CLI tool '$(PKG)' via Devbox..."; \
		echo "Please run: devbox global add $(PKG)"; \
		echo "Then commit: git add .local/share/devbox/global/default/devbox.json"; \
	else \
		echo "TYPE must be 'cli' or 'gui'"; \
		echo "Usage: make packages/add PKG=jq TYPE=cli"; \
		exit 1; \
	fi
```

### 5. Package Search

Help users find packages before adding:

```make
.PHONY: packages/search
packages/search:  ## Search for package. Usage: make packages/search PKG=name
	@test -n "$(PKG)" || (echo "PKG is required. Usage: make packages/search PKG=jq"; exit 1)
	@echo "=== Searching for '$(PKG)' ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew search $(PKG) | head -20
	@echo ""
	@echo "--- Devbox (nixpkgs) ---"
	@echo "Run: devbox search $(PKG)"
	@devbox search $(PKG) 2>/dev/null | head -20 || echo "Install devbox to search nixpkgs"
```

## Implementation Plan

### Step 1: Add devbox/cleanup (15 minutes)

1. Add target to Makefile after `devbox-global-install`
2. Update `packages/cleanup` to call both cleanups
3. Test:
   ```bash
   make devbox/cleanup
   make packages/cleanup
   ```

### Step 2: Add packages/doctor (20 minutes)

1. Add target to "Unified Package Management" section
2. Run and verify output
3. Fix any errors in detection logic
4. Test:
   ```bash
   make packages/doctor
   ```

### Step 3: Add packages/outdated (10 minutes)

1. Add target to Makefile
2. Compare output with individual `brew outdated` and `devbox global list`
3. Test:
   ```bash
   make packages/outdated
   ```

### Step 4: Add packages/add and packages/search (15 minutes)

1. Add both targets
2. Test adding a CLI package:
   ```bash
   make packages/add PKG=htop TYPE=cli
   ```
3. Test adding a GUI package:
   ```bash
   make packages/add PKG=slack TYPE=gui
   ```
4. Test search:
   ```bash
   make packages/search PKG=python
   ```

## Full Makefile Addition

Add this section to the "Unified Package Management" block in Makefile:

```make
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
	@echo "Packages: $$(devbox global list 2>/dev/null | grep -c '✓' || echo 0)"

.PHONY: packages/outdated
packages/outdated:  ## Show outdated packages with details
	@echo "=== Outdated Packages ==="
	@echo ""
	@echo "--- Homebrew ---"
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew outdated --greedy --verbose || echo "✓ All up to date"
	@echo ""
	@echo "--- Devbox ---"
	@echo "Devbox uses latest nixpkgs. Run 'devbox global update' to update."

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

.PHONY: packages/search
packages/search:  ## Search for package (PKG=name)
	@test -n "$(PKG)" || (echo "Usage: make packages/search PKG=jq"; exit 1)
	@echo "=== Homebrew ==="
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew search $(PKG) | head -20
	@echo ""
	@echo "=== Devbox ==="
	@devbox search $(PKG) 2>/dev/null | head -20 || echo "Install devbox to search"
```

## Testing

### Test All New Commands

```bash
# Doctor
make packages/doctor

# Outdated
make packages/outdated

# Search
make packages/search PKG=ripgrep

# Add (dry-run, don't actually add)
make packages/add PKG=test-package TYPE=cli  # Will show instructions
```

## Expected Benefits

### Before (After Phase 1)
- ✓ Unified install/update/status
- ✗ No diagnostics
- ✗ No search capability
- ✗ Manual package addition workflow
- ✗ Incomplete cleanup

### After (Phase 3)
- ✓ Complete unified interface
- ✓ Health diagnostics (`packages/doctor`)
- ✓ Package search across both managers
- ✓ Simplified add workflow
- ✓ Complete cleanup for both managers
- ✓ Detailed outdated package reports

### New Commands Summary

| Command | Purpose |
|---------|---------|
| `packages/doctor` | Health check across both package managers |
| `packages/outdated` | Detailed list of outdated packages |
| `packages/search` | Search for packages before installing |
| `packages/add` | Smart routing to correct package manager |
| `devbox/cleanup` | Clean Devbox cache and reinstall |

## Success Criteria

- [ ] All 5 new targets added to Makefile
- [ ] `make packages/doctor` runs successfully
- [ ] `make packages/outdated` shows accurate information
- [ ] `make packages/search PKG=jq` returns results
- [ ] `make packages/add` correctly routes to Devbox/Homebrew
- [ ] `make devbox/cleanup` successfully cleans cache
- [ ] Updated `make help` shows all new commands
- [ ] Documentation updated in README.md
- [ ] Changes committed and pushed

## Related Files

- `Makefile` (Unified Package Management section, around line 123)
- `README.md` (document new commands)
- `AGENTS.md` (update package management section)
