# Phase 2: Deployment Simplification

**Status:** IMPLEMENTED (Alternative Approach)
**Priority:** HIGH
**Estimated Effort:** 30 minutes (actual)
**Impact:** Minimal code change, maintains UNIX philosophy

## Current Problems

### Overly Complex Deployment Logic

**Makefile lines 7-20:** 13 lines of complex pattern expansion
```make
BASE_EXCLUSIONS := $(shell grep -v '^\#' EXCLUSIONS | grep -v '^$$' | tr '\n' ' ')
CANDIDATES_PATTERNS := $(shell grep -v '^\#' CANDIDATES | grep -v '^$$' | tr '\n' ' ')
PARTIAL_LINKS := .local/share/devbox/global/default
PARTIAL_TOPS := $(sort $(foreach p,$(PARTIAL_LINKS),$(firstword $(subst /, ,$(p)))))
EXCLUSIONS := $(BASE_EXCLUSIONS) $(PARTIAL_TOPS)
CANDIDATES := $(foreach pattern,$(CANDIDATES_PATTERNS),$(wildcard $(pattern)))
DOTFILES   = $(filter-out $(EXCLUSIONS), $(CANDIDATES))
```

### Issues:
1. **Three different exclusion mechanisms** (BASE_EXCLUSIONS, PARTIAL_TOPS, EXCLUSIONS file)
2. **Complex pattern expansion** requiring deep Make expertise
3. **PARTIAL_LINKS hardcoded** in Makefile but documented as if in EXCLUSIONS
4. **Cognitive overhead**: Must understand grep, tr, foreach, subst, wildcard, filter-out
5. **Difficult to debug**: Takes 15+ minutes to understand for newcomers

## Implemented Solution

### Minimal Improvement: PARTIAL_LINKS File (UNIX-style approach)

**Decision:** Maintain CANDIDATES/EXCLUSIONS pattern, add PARTIAL_LINKS file

**Rationale:**
- CANDIDATES/EXCLUSIONS follows classic UNIX whitelist/blacklist pattern (similar to rsync, tar)
- Current approach is not actually "complex" for UNIX users - it's standard text processing
- Make functions (foreach, filter-out, etc.) are expected knowledge for Makefile users
- Only real issue was hardcoded PARTIAL_LINKS in Makefile

**Changes Made:**
1. Created `PARTIAL_LINKS` file with same format as CANDIDATES/EXCLUSIONS
2. Updated Makefile to load PARTIAL_LINKS from file instead of hardcoding
3. Added clear comments explaining the deployment configuration flow

**Benefits:**
- ✅ Eliminates hardcoded configuration
- ✅ Maintains consistency (all config in external files)
- ✅ Preserves UNIX philosophy
- ✅ No learning curve - same pattern as existing files
- ✅ Easy to extend (just add lines to PARTIAL_LINKS)

---

## Alternative Considered: Declarative Deployment Config

This option was considered but rejected in favor of maintaining UNIX conventions.

#### New File: `deploy.conf`

```ini
# Dotfiles Deployment Configuration
# Simple, declarative format for managing symlinks

# ==========================================
# Standard Deployments (Simple Symlinks)
# ==========================================
# These files/directories will be symlinked directly to $HOME
[deploy]
.vimrc
.gvimrc
.gitconfig
.gitignore
.tmux.conf
.zshrc
bin
etc
.config/fish
.config/iterm2

# ==========================================
# Partial Links (Selective Nested Paths)
# ==========================================
# Parent directories are excluded, but specific children are symlinked
# Format: full/path/to/target
[partial]
.local/share/devbox/global/default

# ==========================================
# Special Cases
# ==========================================
# File-level links where parent directory is excluded
[special]
.claude/CLAUDE.md
```

#### Simplified Makefile Deployment Logic

Replace lines 7-20 with approximately 30 lines total:

```make
# Load deployment configuration from deploy.conf
DEPLOY_CONF := $(DOTPATH)/deploy.conf

# Extract [deploy] section
DEPLOY_FILES := $(shell awk '/^\[deploy\]/,/^\[/ {if ($$0 !~ /^\[/ && $$0 !~ /^#/ && $$0 !~ /^$$/) print}' $(DEPLOY_CONF))

# Extract [partial] section
PARTIAL_LINKS := $(shell awk '/^\[partial\]/,/^\[/ {if ($$0 !~ /^\[/ && $$0 !~ /^#/ && $$0 !~ /^$$/) print}' $(DEPLOY_CONF))

# Extract [special] section
SPECIAL_FILES := $(shell awk '/^\[special\]/,/^\[/ {if ($$0 !~ /^\[/ && $$0 !~ /^#/ && $$0 !~ /^$$/) print}' $(DEPLOY_CONF))

# Build exclusion list from partial links (extract top-level directories)
PARTIAL_EXCLUSIONS := $(sort $(foreach p,$(PARTIAL_LINKS),$(firstword $(subst /, ,$(p)))))

# All deployable files (excluding partials)
DOTFILES := $(filter-out $(PARTIAL_EXCLUSIONS), $(DEPLOY_FILES))
```

#### Updated `deploy` target

```make
.PHONY: deploy
deploy: ## Deploy dotfiles
	@echo "Deploying dotfiles..."
	@if ! [ -L $(HOME)/.config ]; then mv $(HOME)/.config $(HOME)/.config~; fi

	# Standard deployments
	@$(foreach val, $(DOTFILES), ln -sfnv $(DOTPATH)/$(val) $(HOME)/$(val);)

	# Partial links
	@$(foreach path, $(PARTIAL_LINKS), \
		mkdir -p $(HOME)/$(dir $(path)); \
		rm -rf $(HOME)/$(path); \
		ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path);)

	# Special files
	@$(foreach path, $(SPECIAL_FILES), \
		mkdir -p $(HOME)/$(dir $(path)); \
		ln -sfnv $(DOTPATH)/$(path) $(HOME)/$(path);)

	@chown $$(id -un):$$(id -gn) ~/.ssh
	@chmod 0700 ~/.ssh
	@echo "✓ Deployment complete"
```

## Implementation Steps

### Step 1: Create deploy.conf (10 minutes)

1. Read CANDIDATES file to understand current patterns
2. Create `deploy.conf` with [deploy], [partial], and [special] sections
3. Populate sections based on current CANDIDATES patterns

```bash
# Create the file
touch deploy.conf

# Verify patterns match current deployment
make deploy/dry-run  # Before changes
```

### Step 2: Update Makefile (30 minutes)

1. Backup current Makefile:
   ```bash
   cp Makefile Makefile.backup
   ```

2. Replace lines 7-20 with new simplified logic

3. Update `deploy` target with clearer structure

4. Remove CANDIDATES and EXCLUSIONS files (keep backup)

### Step 3: Test in Sandbox (30 minutes)

Test deployment in a temporary directory:

```bash
# Create sandbox
SANDBOX=$(mktemp -d)
echo "Testing in: $SANDBOX"

# Test deployment
HOME=$SANDBOX make deploy

# Verify symlinks were created correctly
find $SANDBOX -type l -ls

# Check for broken symlinks
find $SANDBOX -type l ! -exec test -e {} \; -print

# Cleanup
rm -rf $SANDBOX
```

### Step 4: Test on Real System (30 minutes)

1. **Dry run first:**
   ```bash
   make deploy/dry-run
   ```

2. **Compare with current deployment:**
   ```bash
   # Save current symlink state
   find ~ -maxdepth 1 -type l -ls > /tmp/before-deploy.txt

   # Run new deployment
   make deploy

   # Compare
   find ~ -maxdepth 1 -type l -ls > /tmp/after-deploy.txt
   diff /tmp/before-deploy.txt /tmp/after-deploy.txt
   ```

3. **Verify critical symlinks:**
   ```bash
   ls -la ~/.vimrc ~/.gitconfig ~/.config/fish ~/.local/share/devbox/global/default
   ```

### Step 5: Test on Secondary Machine (30 minutes)

If you have access to iMac or another machine:

1. Pull changes
2. Run `make deploy`
3. Verify all expected symlinks are created
4. Check for any errors or warnings

### Step 6: Documentation Update (20 minutes)

1. Update README.md to mention `deploy.conf`
2. Update AGENTS.md deployment section
3. Add migration notes to ADR.md:
   ```markdown
   ## 2026-01-XX: Simplified Deployment Configuration

   **Decision:** Replace CANDIDATES/EXCLUSIONS with deploy.conf

   **Rationale:** Reduce complexity from 3 files + complex Make logic to 1 declarative file

   **Impact:** 60% reduction in deployment logic complexity, easier onboarding
   ```

## Expected Benefits

### Before (Current State)
- **Configuration files:** 3 (Makefile, CANDIDATES, EXCLUSIONS)
- **Lines of deployment logic:** 13 lines of complex Make
- **Concepts to understand:** grep, tr, foreach, subst, wildcard, filter-out, shell expansion
- **Time to understand:** 15+ minutes for newcomers
- **Special case handling:** Scattered across multiple files

### After (Proposed State)
- **Configuration files:** 1 (deploy.conf)
- **Lines of deployment logic:** ~30 lines (but much clearer)
- **Concepts to understand:** INI-style sections, simple awk parsing
- **Time to understand:** 2-5 minutes
- **Special case handling:** Clearly labeled in [special] section

### Improvement Metrics
- **60% reduction** in cognitive load
- **67% reduction** in config files (3 → 1)
- **Clearer semantics** with explicit [deploy], [partial], [special] sections
- **Easier to modify** - just add a line to appropriate section
- **Self-documenting** - section names explain purpose

## Rollback Plan

If issues are discovered:

```bash
# Restore original Makefile
cp Makefile.backup Makefile

# Restore CANDIDATES and EXCLUSIONS
git restore CANDIDATES EXCLUSIONS

# Re-deploy with old system
make deploy
```

Keep backups until new system is proven on all machines (1-2 weeks).

## Alternative: Use GNU Stow

**Note:** Per ADR.md, we explicitly decided against specialized dotfiles managers like Stow to minimize dependencies.

If willing to reconsider this decision:
- GNU Stow provides automatic symlink management
- Simpler than custom deployment logic
- Well-tested and maintained
- Adds external dependency

**Recommendation:** Stick with custom solution as per ADR

## Success Criteria

- [ ] deploy.conf created and populated
- [ ] Makefile simplified (deployment logic < 40 lines)
- [ ] All tests pass in sandbox
- [ ] Deployment works on primary machine (MacBook Air)
- [ ] Deployment works on secondary machine (iMac)
- [ ] No broken symlinks
- [ ] Documentation updated
- [ ] Old CANDIDATES/EXCLUSIONS files removed
- [ ] Changes committed and pushed

## Related Files

- `Makefile` (lines 7-39)
- `CANDIDATES`
- `EXCLUSIONS`
- `README.md`
- `AGENTS.md`
- `ADR.md`
