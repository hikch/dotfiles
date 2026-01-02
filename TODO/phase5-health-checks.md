# Phase 5: Health Checks & Diagnostics

**Priority:** LOW-MEDIUM
**Estimated Effort:** 1-2 hours
**Impact:** Proactive issue detection, faster debugging

## Current State

### Phase 1 Accomplishments (Already Implemented)

Basic health check added in Phase 1:

```make
.PHONY: status
status:  ## Show repository and package status
	@echo "=== Git Status ==="
	@git status --short
	@echo ""
	@echo "=== Broken Symlinks in HOME ==="
	@find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v ".Trash" || echo "No broken symlinks found"
	@echo ""
	@$(MAKE) --no-print-directory packages/status
```

## Remaining Gaps

### Missing Diagnostics

1. **No deployment verification**
   - Can't verify all expected symlinks exist
   - Can't detect deployment drift (files in repo but not deployed)

2. **No tool availability checks**
   - Don't know if essential tools are in PATH
   - Can't verify tool versions

3. **No comprehensive health check**
   - `make status` is basic
   - No `make doctor` for deep diagnostics

4. **No symlink integrity check**
   - Only checks for broken links
   - Doesn't verify symlinks point to correct dotfiles repo

## Proposed Enhancements

### 1. Comprehensive make doctor

A thorough diagnostic command that checks everything:

```make
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
```

### 2. Deployment Verification

Check that all files in dotfiles repo are properly deployed:

```make
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
```

### 3. Enhanced Symlink Integrity Check

More comprehensive than current implementation:

```make
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
```

### 4. Tool Availability Check

Verify essential tools are installed and accessible:

```make
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
```

### 5. Deployment Drift Detection

Find files that exist in HOME but not in repo:

```make
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
```

### 6. SSH Configuration Check

Verify SSH keys and permissions:

```make
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
```

## Implementation Plan

### Step 1: Add Individual Doctor Targets (30 minutes)

Add all helper targets:
- `doctor/deployment`
- `doctor/symlinks`
- `doctor/tools`
- `doctor/drift`
- `doctor/ssh`

Test each individually:
```bash
make doctor/deployment
make doctor/symlinks
make doctor/tools
make doctor/drift
make doctor/ssh
```

### Step 2: Create Main doctor Target (15 minutes)

Combine all checks into main `doctor` target.

Test:
```bash
make doctor
```

### Step 3: Enhance Existing status Target (15 minutes)

Update `make status` to be more informative:

```make
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
```

### Step 4: Add Makefile Help Text (5 minutes)

Ensure all new targets have help text:

```make
.PHONY: doctor
doctor:  ## Run comprehensive health checks

.PHONY: doctor/deployment
doctor/deployment:  ## Verify deployment status

.PHONY: doctor/symlinks
doctor/symlinks:  ## Check symlink integrity

.PHONY: doctor/tools
doctor/tools:  ## Verify tool availability

.PHONY: doctor/drift
doctor/drift:  ## Detect untracked dotfiles

.PHONY: doctor/ssh
doctor/ssh:  ## Check SSH configuration
```

### Step 5: Update Documentation (15 minutes)

**README.md:**
```markdown
## Health Checks

### Quick Status
```bash
make status
```
Shows git status, broken symlinks, and package summary.

### Comprehensive Diagnostics
```bash
make doctor
```
Runs thorough health checks including:
- Repository status
- Deployment verification
- Symlink integrity
- Tool availability
- Package health
- Shell environment

### Individual Checks
```bash
make doctor/deployment  # Verify deployment status
make doctor/symlinks    # Check symlink integrity
make doctor/tools       # Verify tool availability
make doctor/drift       # Detect untracked dotfiles
make doctor/ssh         # Check SSH configuration
```
```

**AGENTS.md:**
```markdown
## Diagnostic Commands
- `make status`: Quick health check
- `make doctor`: Comprehensive diagnostics
- `make doctor/<check>`: Individual health checks
- See `make help` for full list
```

## Testing

### Test Individual Checks

```bash
# Each should run without errors
make doctor/deployment
make doctor/symlinks
make doctor/tools
make doctor/drift
make doctor/ssh
```

### Test Main Doctor Command

```bash
# Should show comprehensive report
make doctor
```

### Test Error Detection

Intentionally break things to verify detection:

```bash
# Break a symlink
rm ~/.vimrc
make doctor/deployment  # Should detect missing file

# Restore
make deploy
make doctor/deployment  # Should show OK

# Remove a tool from PATH
export PATH=/usr/bin
make doctor/tools  # Should show missing tools

# Restore
export PATH="$ORIGINAL_PATH"
```

## Expected Benefits

### Before (After Phase 1)
- Basic `make status` command
- Shows git status, broken symlinks, package status
- No deployment verification
- No tool availability check
- No drift detection

### After (Phase 5)
- Comprehensive `make doctor` command
- Deployment verification
- Symlink integrity checks
- Tool availability verification
- Drift detection
- SSH configuration check
- Detailed, actionable diagnostics

### Use Cases

| Scenario | Command | Result |
|----------|---------|--------|
| Quick daily check | `make status` | Fast overview |
| Before deployment | `make doctor` | Verify current state |
| After deployment | `make doctor/deployment` | Confirm success |
| Troubleshooting | `make doctor` | Identify issues |
| New machine setup | `make doctor` | Verify completeness |
| Before updates | `make doctor` | Baseline check |

## Success Criteria

- [ ] All `doctor/*` targets implemented
- [ ] Main `doctor` target works
- [ ] Updated `status` target
- [ ] All targets have help text
- [ ] Documentation updated
- [ ] Tests pass on both machines
- [ ] False positives minimized
- [ ] Actionable error messages
- [ ] Changes committed and pushed

## Future Enhancements (Optional)

### Phase 5.1: Automated Fixes

Add `make doctor/fix` to automatically fix common issues:

```make
.PHONY: doctor/fix
doctor/fix:  ## Automatically fix common issues
	@echo "Fixing common issues..."
	# Fix broken symlinks by re-deploying
	@make deploy
	# Fix SSH permissions
	@chmod 700 ~/.ssh
	# Reinstall missing packages
	@make packages/install
```

### Phase 5.2: Performance Monitoring

Track dotfiles deployment and tool startup times:

```make
.PHONY: doctor/performance
doctor/performance:  ## Check environment performance
	@echo "Measuring shell startup time..."
	@time fish -c 'exit'
	@time zsh -c 'exit'
```

### Phase 5.3: CI/CD Integration

Run doctor checks in GitHub Actions for pull requests.

## Related Files

- `Makefile` (add doctor targets around line 50-60)
- `README.md` (document new commands)
- `AGENTS.md` (update diagnostic commands section)
