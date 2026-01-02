# Dotfiles Improvement Roadmap

This directory contains the planned improvements for simplifying and enhancing the dotfiles management system.

## Overview

Based on a comprehensive analysis of the current dotfiles repository, we've identified several areas for improvement. The work is divided into 5 phases, each focusing on specific aspects of the system.

## Progress

### ✅ Phase 1: Quick Wins (Completed)

**Status:** Completed on 2026-01-02
**Commit:** `d1ac5b7`

**Achievements:**
- ✅ Added unified package management commands (`packages/*`)
- ✅ Added `make status` for environment health checks
- ✅ Added `make deploy/dry-run` for safer testing
- ✅ Removed 39 lines of deprecated Nix code
- ✅ Consolidated AI documentation (AGENTS.md + CLAUDE.md)
- ✅ Documented PARTIAL_LINKS in EXCLUSIONS file

**Impact:** Immediate usability improvements with zero risk

---

### 📋 Phase 2: Deployment Simplification

**Status:** Planned
**Estimated Effort:** 2-3 hours
**Priority:** HIGH

**Goals:**
- Reduce deployment complexity by 60%
- Replace pattern expansion with declarative config
- Simplify from 3 config files to 1

**Details:** See [phase2-deployment-simplification.md](./phase2-deployment-simplification.md)

---

### 📋 Phase 3: Package Management Consolidation

**Status:** Planned
**Estimated Effort:** 1 hour
**Priority:** MEDIUM-HIGH

**Goals:**
- Expand `packages/*` commands with additional features
- Implement `devbox/cleanup`
- Add `packages/doctor` for health checks

**Details:** See [phase3-package-management.md](./phase3-package-management.md)

---

### 📋 Phase 4: Shell Configuration Cleanup

**Status:** Planned
**Estimated Effort:** 2 hours
**Priority:** MEDIUM

**Goals:**
- Remove 5 unused shell configuration files
- Consolidate .zsh* files into minimal .zshrc
- Align documentation with reality (Fish is primary shell)

**Details:** See [phase4-shell-cleanup.md](./phase4-shell-cleanup.md)

---

### 📋 Phase 5: Health Checks & Diagnostics

**Status:** Planned
**Estimated Effort:** 1-2 hours
**Priority:** LOW-MEDIUM

**Goals:**
- Implement `make doctor` for comprehensive diagnostics
- Add deployment drift detection
- Add broken symlink detection

**Details:** See [phase5-health-checks.md](./phase5-health-checks.md)

---

## Summary Metrics

### Current Complexity (After Phase 1)
- Deployment mechanism: 7/10 complexity
- Package management: 4/10 complexity (improved from 6/10)
- Documentation: 3/10 fragmentation (improved from 5/10)
- Legacy burden: 3/10 (improved from 6/10)

### After All Improvements
- Deployment mechanism: 3/10 (Phase 2)
- Package management: 2/10 (Phase 3)
- Documentation: 2/10 (already improved)
- Legacy burden: 1/10 (Phase 4)

### Total Effort Estimate
- Phase 1: ✅ ~1 hour (completed)
- Phase 2: ~2-3 hours
- Phase 3: ~1 hour
- Phase 4: ~2 hours
- Phase 5: ~1-2 hours
- **Total remaining:** ~6-8 hours

### Expected Impact
- **60% reduction** in deployment complexity
- **Unified interface** for package management
- **Proactive diagnostics** to prevent issues
- **Cleaner codebase** with minimal legacy burden

## Recommendations

1. **Start with Phase 2** - Highest impact on reducing cognitive load
2. **Then Phase 3** - Builds on Phase 1 improvements
3. **Consider Phase 4 and 5 as time permits** - Quality-of-life improvements

## References

- **ADR.md** - Architectural decision records
- **AGENTS.md** - Repository guidelines for AI assistants
- **Makefile** - Current implementation
- **CANDIDATES** / **EXCLUSIONS** - Deployment configuration
