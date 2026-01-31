# Global Git Hooks

> **Note**: This is a translation. Primary version (Japanese): [README.ja.md](README.ja.md)

Global Git hooks management system that automatically runs security checks across all Git repositories.

## Overview

This directory manages global hooks using Git's `init.templateDir` feature. Hooks are automatically deployed to new and existing repositories while coexisting with project-specific hook systems.

### Why init.templateDir?

- **Problem with core.hooksPath**: Tools like Husky override global settings with local configuration
- **Benefits of init.templateDir**:
  - Automatically applied to new repositories
  - Existing repositories can be updated in bulk via update script
  - No conflicts with project-specific hook systems (Husky, pre-commit framework)

## Directory Structure

```
.config/git/
├── hooks/
│   ├── pre-commit          # Smart wrapper hook (actual implementation)
│   └── README.md           # This file
├── ignore                  # Global .gitignore
└── template/
    └── hooks/
        └── pre-commit      # Symlink for template
```

## Smart Wrapper Hook Behavior

The `pre-commit` hook operates in the following order:

### Phase 1: Gitleaks Secret Detection (Required Security Check)

1. **Run gitleaks**: Execute secret detection on staged changes
2. **Skip condition**: Avoid duplicate execution if gitleaks is already configured in pre-commit framework
3. **On detection**: Block commit when secrets are detected

### Phase 2: Project Hook Delegation (Priority Order)

Detect and delegate to project-specific hook systems appropriately:

**Priority 1: pre-commit framework**
- Detection: Presence of `.pre-commit-config.yaml`
- Behavior: Execute `pre-commit run`
- Use case: Standard hook management widely used in Python ecosystem

**Priority 2: Husky**
- Detection: Presence of `.husky/pre-commit`
- Behavior: Execute Husky's pre-commit script
- Use case: Widely used in Node.js projects

**Priority 3: Local Manual Hooks**
- Detection: Presence of `.git/hooks.local/pre-commit`
- Behavior: Execute local hook
- Use case: Legacy pattern, manually managed hooks

**Priority 4: Project Scripts**
- Detection: Presence of `scripts/pre-commit` (executable)
- Behavior: Execute project's custom script
- Use case: Custom hook management patterns

## Setup

### Initial Setup

```bash
# 1. Configure Git template directory
git config --global init.templateDir ~/.config/git/template

# 2. Apply to existing repositories (optional)
~/bin/git-hooks-update
```

### Via Makefile

```bash
# Full setup (update gitconfig + existing repositories)
make git-hooks-setup

# Update existing repositories only
make git-hooks-update
```

## Automatic Application to New Repositories

Once `init.templateDir` is configured, hooks are automatically applied with the following operations:

```bash
# Create new repository
git init my-project

# Clone remote repository
git clone https://github.com/user/repo.git
```

In both cases, `.git/hooks/pre-commit` is automatically created.

## Applying to Existing Repositories

### Manual Application (Single Repository)

```bash
cd /path/to/existing/repo
git init
```

Running `git init` in an existing repository reapplies the template (existing files are not overwritten).

### Bulk Application (All Repositories)

```bash
# Update all repositories under ~/dev/
~/bin/git-hooks-update ~/dev

# Specific directories only
~/bin/git-hooks-update ~/projects/work ~/projects/personal
```

## Coexistence with Project-Specific Hooks

### For Husky Projects

The global hook automatically detects Husky and delegates to `.husky/pre-commit`:

```
Execution order:
1. Global hook: Run gitleaks
2. Global hook: Detect Husky
3. Husky: Execute .husky/pre-commit
```

### For pre-commit Framework

When gitleaks is configured in `.pre-commit-config.yaml`, duplicate execution is avoided:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

```
Execution order:
1. Global hook: Detect gitleaks configuration, skip
2. Global hook: Delegate to pre-commit framework
3. pre-commit: Execute all hooks including gitleaks
```

When gitleaks is not configured:

```
Execution order:
1. Global hook: Run gitleaks
2. Global hook: Delegate to pre-commit framework
3. pre-commit: Execute all configured hooks
```

### For Local Manual Hooks

Existing manual hooks continue to run if moved to `.git/hooks.local/`:

```bash
# Move existing hook
mkdir -p .git/hooks.local
mv .git/hooks/pre-commit .git/hooks.local/pre-commit
git init  # Apply global hook
```

## Hook Customization

### Disable Global Hook for a Project

To skip the global hook in a specific project:

```bash
# Disable locally in project
cd /path/to/project
rm .git/hooks/pre-commit

# Or replace with empty hook
echo '#!/bin/sh' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Customize gitleaks Configuration

Place `.gitleaks.toml` in the project root to apply project-specific configuration:

```bash
# Copy dotfiles configuration and edit
cp ~/.gitleaks.toml ./.gitleaks.toml
git add .gitleaks.toml
```

## Troubleshooting

### Hook Not Executing

```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# Check execution permissions
ls -l .git/hooks/pre-commit

# Manually reapply
git init
```

### gitleaks Not Installed

```bash
# Install via Devbox
devbox global add gitleaks@latest

# Or via Homebrew
brew install gitleaks
```

### Duplicate Execution with pre-commit Framework

If gitleaks is configured in `.pre-commit-config.yaml`, it's automatically skipped. If not skipped, verify the configuration:

```bash
# Check if gitleaks is configured
grep -i gitleaks .pre-commit-config.yaml
```

### Husky Stopped Working

The global hook detects and delegates to Husky, so this shouldn't normally be an issue. If it doesn't work:

```bash
# Check if Husky is correctly configured
ls -la .husky/pre-commit

# Reinstall Husky
npm install
npx husky install
```

## Security Considerations

### Limitations of Secret Detection

While gitleaks is a powerful tool, it cannot detect all secrets:

- **False positives**: Regex-based detection may produce false positives
- **Missed detections**: Custom secret formats may not be detected
- **Encrypted data**: Already encrypted data is not detected

### Defense in Depth Approach

1. **Pre-commit**: This global hook (gitleaks)
2. **Repository level**: Exclude secret files via `.gitignore`
3. **Environment variables**: Use `.env` files, commit only `.env.example`
4. **CI/CD**: Additional scanning via GitHub Actions, etc.
5. **Periodic scans**: Scan entire history with `make security-scan`

### Using Bypass

Hooks can be bypassed with the `--no-verify` flag, but this is not recommended:

```bash
# Use only in emergencies (not recommended)
git commit --no-verify -m "emergency fix"
```

If bypassed, fix it later:

```bash
# Amend last commit
git reset --soft HEAD~1
# Remove secrets
vim file-with-secret.txt
# Recommit (with hook)
git add file-with-secret.txt
git commit -m "fix: remove secrets"
```

## Related Documentation

- [gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [pre-commit Framework](https://pre-commit.com/)
- [Husky](https://typicode.github.io/husky/)

## References

This system is based on the following best practices:

- **Defense in Depth**: Prevent secret leaks through multiple layers of defense
- **Convention over Configuration**: Automatically detect standard hook systems
- **Non-Breaking**: Don't disrupt existing project workflows
- **Transparency**: Clearly log hook behavior
