# Phase 4: Shell Configuration Cleanup

**Priority:** MEDIUM
**Estimated Effort:** 2 hours
**Impact:** Remove legacy burden, align with documented strategy

## Current Problem

### Too Many Shell Configuration Files

According to ADR.md, **Fish is the primary interactive shell**, yet the repository tracks 7 shell configuration files:

```bash
.bashrc          # Legacy bash
.bash_profile    # Legacy bash
.zshrc           # Zsh compatibility
.zshenv          # Zsh environment
.zprofile        # Zsh profile
.shellrc         # POSIX shells
.profile         # POSIX shells
```

Only `.config/fish/config.fish` is actively used for interactive shells.

### Why This is a Problem

1. **Maintenance burden**: 7 files to keep synchronized
2. **Confusion**: Unclear which shell is actually used
3. **Documentation mismatch**: ADR.md says Fish is primary, but bash/zsh files suggest otherwise
4. **Redundancy**: Multiple files doing similar things

### ADR Justification

From ADR.md line 15:
> "Maintain `.zshrc` for system compatibility (Docker Desktop, Devbox default shell) even if Zsh is not the primary interactive shell."

**Key insight:** We only need `.zshrc` for **system compatibility**, not for interactive use.

## Proposed Solution

### Keep Files (Essential for Compatibility)

**1. `.zshrc` - Minimal Zsh compatibility**
```zsh
# Minimal Zsh configuration for system compatibility
# Docker Desktop and Devbox may invoke zsh for scripts
# Primary interactive shell is Fish (see .config/fish/config.fish)

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Devbox
eval "$(devbox global shellenv --init-hook)"

# PATH extensions
export PATH="$HOME/bin:$PATH"

# Note: For interactive shell configuration, use Fish
# Run: fish
```

**2. `.config/fish/config.fish` - Primary interactive shell**
(Keep as-is, this is actively used)

### Delete Files (No Longer Needed)

| File | Reason for Deletion |
|------|---------------------|
| `.bashrc` | Bash not used; functionality covered by .zshrc |
| `.bash_profile` | Bash not used |
| `.zshenv` | Consolidate into .zshrc |
| `.zprofile` | Consolidate into .zshrc |
| `.shellrc` | POSIX shell not used |
| `.profile` | POSIX shell not used |

## Implementation Plan

### Step 1: Backup Current Files (5 minutes)

```bash
# Create backup directory
mkdir -p ~/dotfiles-shell-backup
cp .bashrc .bash_profile .zshrc .zshenv .zprofile .shellrc .profile ~/dotfiles-shell-backup/
echo "Backup created in ~/dotfiles-shell-backup"
```

### Step 2: Consolidate .zsh* Files (20 minutes)

1. **Review current .zsh* files**
   ```bash
   cat .zshrc .zshenv .zprofile
   ```

2. **Identify essential content**
   - Homebrew initialization
   - Devbox initialization
   - PATH modifications
   - Any Docker Desktop requirements

3. **Create minimal .zshrc**

Create new `.zshrc` with only essential content:

```zsh
# ~/.zshrc
# Minimal Zsh configuration for system compatibility
# Primary interactive shell: Fish (see .config/fish/config.fish)

# ==========================================
# Essential System Initialization
# ==========================================

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Devbox
if command -v devbox > /dev/null 2>&1; then
    eval "$(devbox global shellenv --init-hook)"
fi

# ==========================================
# PATH Configuration
# ==========================================

# User binaries
export PATH="$HOME/bin:$PATH"

# ==========================================
# Note
# ==========================================
# This file is minimal by design for system compatibility only.
# For interactive shell customization, use Fish:
#   chsh -s $(which fish)
#   fish
```

### Step 3: Test Zsh Compatibility (30 minutes)

Test that minimal .zshrc works for system tools:

```bash
# Test Zsh can start
zsh -c 'echo $SHELL'

# Test Homebrew available
zsh -c 'which brew'

# Test Devbox available
zsh -c 'which devbox'

# Test PATH includes ~/bin
zsh -c 'echo $PATH | grep $HOME/bin'

# Test Docker Desktop compatibility (if installed)
docker run --rm -it alpine sh -c 'echo $SHELL'

# Test Devbox shell
cd /tmp && devbox init && devbox shell
# Inside shell: echo $SHELL (should be zsh or similar)
# Exit: exit
```

### Step 4: Remove Obsolete Files (15 minutes)

After confirming .zshrc works:

```bash
# Remove from git
git rm .bashrc .bash_profile .zshenv .zprofile .shellrc .profile

# Verify removal
git status

# Check CANDIDATES file - remove these files if listed
vim CANDIDATES
```

### Step 5: Update CANDIDATES/EXCLUSIONS (10 minutes)

```bash
# Edit CANDIDATES - remove old shell files, keep only:
#   .zshrc
#   .config

# Edit EXCLUSIONS - add note about shell files:
echo "# Legacy shell configs (removed in Phase 4)" >> EXCLUSIONS
```

### Step 6: Update Documentation (20 minutes)

**Update ADR.md:**
```markdown
## 2026-01-XX: Shell Configuration Cleanup

**Decision:** Remove legacy bash and redundant zsh configuration files

**Rationale:**
- Fish is the primary interactive shell
- Only .zshrc needed for Docker Desktop and Devbox compatibility
- Reduced from 7 shell configs to 1 (+ Fish config)

**Files Removed:**
- .bashrc, .bash_profile (bash not used)
- .zshenv, .zprofile (consolidated into .zshrc)
- .shellrc, .profile (POSIX shells not used)

**Files Kept:**
- .zshrc (minimal, for system compatibility)
- .config/fish/config.fish (primary interactive shell)
```

**Update README.md:**
```markdown
## Shell Configuration

This repository uses **Fish** as the primary interactive shell.

**Shell Files:**
- `.config/fish/config.fish` - Main shell configuration
- `.zshrc` - Minimal Zsh config for system compatibility only

To use Fish:
```bash
# Install Fish (already in Devbox global packages)
devbox global install

# Set as default shell
chsh -s $(which fish)

# Restart terminal
```

For system tools (Docker, Devbox scripts), Zsh is used with minimal configuration.
```

**Update AGENTS.md:**
```markdown
## Shell Configuration

- Primary shell: **Fish** (`.config/fish/config.fish`)
- Compatibility shell: **Zsh** (`.zshrc`, minimal config for system tools)
- Legacy configs removed: bash, POSIX shell files
```

### Step 7: Test on All Machines (30 minutes)

**MacBook Air:**
```bash
# Deploy changes
make deploy

# Test Fish still works
fish -c 'echo $SHELL'

# Test Zsh compatibility
zsh -c 'which brew && which devbox'

# Test Docker Desktop (if installed)
docker run --rm alpine sh -c 'echo OK'
```

**iMac (if available):**
- Repeat same tests
- Verify no breakage

### Step 8: Monitor for Issues (1 week)

Keep backups for 1 week and monitor for:
- Docker Desktop issues
- Devbox script failures
- Missing environment variables
- Tool availability problems

## Rollback Plan

If issues discovered:

```bash
# Restore backup files
cp ~/dotfiles-shell-backup/* ~/dotfiles/

# Re-add to git
git add .bashrc .bash_profile .zshenv .zprofile .shellrc .profile

# Restore deployment
make deploy

# Commit rollback
git commit -m "Revert: shell cleanup (issues found)"
```

## Testing Checklist

Test these scenarios to ensure nothing breaks:

### Interactive Shell
- [ ] Fish starts correctly
- [ ] Fish has all expected tools in PATH
- [ ] Fish plugins load
- [ ] Prompt displays correctly

### Zsh Compatibility
- [ ] Zsh can start: `zsh -c 'echo OK'`
- [ ] Homebrew available: `zsh -c 'brew --version'`
- [ ] Devbox available: `zsh -c 'devbox version'`
- [ ] ~/bin in PATH: `zsh -c 'echo $PATH | grep bin'`

### Docker Desktop
- [ ] Docker commands work: `docker ps`
- [ ] Docker run works: `docker run alpine echo OK`
- [ ] Docker-compose works (if used)

### Devbox
- [ ] Devbox shell works: `devbox shell`
- [ ] Devbox scripts work: `devbox run <script>`
- [ ] Global packages accessible

### Other Tools
- [ ] `make` commands work
- [ ] Git operations work
- [ ] SSH connections work
- [ ] tmux sessions work (if used)

## Expected Benefits

### Before (Current State)
- **7 shell config files** tracked
- **Unclear** which shell is primary
- **Maintenance burden** keeping files in sync
- **Documentation mismatch** (Fish is primary, but many configs suggest otherwise)

### After (Phase 4)
- **2 shell config files** (`.zshrc` + `.config/fish/config.fish`)
- **Clear** documentation: Fish is primary
- **Minimal** maintenance burden
- **Aligned** with ADR.md decision

### Metrics
- **71% reduction** in shell config files (7 → 2)
- **Clearer identity**: Fish is primary, zsh for compatibility
- **Simplified** deployment (fewer files to track)
- **Better documentation** alignment

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Docker Desktop breaks | HIGH | Test thoroughly before deletion; keep backups |
| Devbox scripts fail | HIGH | Verify .zshrc has all Devbox init |
| SSH login issues | MEDIUM | Test SSH to ensure shell loads |
| Missing env vars | MEDIUM | Compare old vs new shell startup |
| Tool PATH issues | MEDIUM | Verify all tools accessible in zsh |

## Related Files

- `.zshrc` (consolidate and simplify)
- `.bashrc`, `.bash_profile`, `.zshenv`, `.zprofile`, `.shellrc`, `.profile` (delete)
- `.config/fish/config.fish` (keep as-is)
- `CANDIDATES` (update)
- `EXCLUSIONS` (update)
- `README.md` (document change)
- `ADR.md` (record decision)
- `AGENTS.md` (update shell info)

## Success Criteria

- [ ] Minimal .zshrc created and tested
- [ ] 6 legacy shell files removed from git
- [ ] CANDIDATES/EXCLUSIONS updated
- [ ] Documentation updated (ADR, README, AGENTS)
- [ ] All compatibility tests pass
- [ ] Changes deployed on all machines
- [ ] No issues reported after 1 week
- [ ] Backups deleted after confirmation period
