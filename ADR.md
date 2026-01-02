# Architecture Decision Records (ADR)

Simple journal-style decisions for this dotfiles repository.

## 2025-08-25

- **Brewfile host-specific includes**: Added `hosts/` directory with automatic hostname-based includes to `.Brewfile` for machine-specific package management
- **Package management separation**: Moved CLI tools (`mas`, `syncthing`) from Homebrew to Devbox, keeping Homebrew Cask for GUI applications only
- **Makefile brew operations**: Added comprehensive `make brew/*` targets for daily Homebrew Bundle operations with improved verbose output
- **Service management policy**: Defined clear separation of responsibility for background services:
  - `brew services` → For system-wide, always-on daemons (e.g., tailscaled, syncthing, shared Postgres/Redis, GUI agents). Managed via brew services and integrated with LaunchAgents/Daemons.
  - `devbox services` → For project-scoped or version-pinned dependencies (e.g., Postgres/Redis/Minio for development). Started/stopped alongside project environments for reproducibility.
  - Rule of thumb: system-wide → brew, project-specific → devbox.
- **Setup Tooling**: Use `Makefile` and `bootstrap.sh` for initial setup. This minimizes dependencies, requiring only standard tools like `git` and `make`, and avoids needing to install specialized dotfiles managers (e.g., Stow, chezmoi).
- **`.zshrc` Compatibility**: Maintain `.zshrc` for system compatibility, as Zsh is the default shell on macOS. This ensures tools that rely on Zsh for initialization (e.g., Docker, Devbox) function correctly, even if Zsh is not the primary interactive shell.
- **Layout Principle (Home Directory Mirror)**: The repository's root is structured to be a direct mirror of the user's home directory (`~/`). This principle dictates the location of all dotfiles.
    - **Rationale**: This simplifies deployment to a simple copy or symlink operation.
    - **Examples**: As a result, files like `.vimrc`, `.gvimrc`, and `.ansible.cfg` are placed in the root of the repository, corresponding to their intended location in `~/` and ensuring automatic discovery by their respective applications.

## 2025-08-29

- **AI Tools Configuration Strategy**: Established configuration management for AI development tools (Claude Code, Gemini CLI) with dynamic environment awareness:
  - **Approach**: Use EXCLUSIONS/CANDIDATES deployment control rather than complex .gitignore patterns for granular file-level deployment
  - **Claude Code**: `.claude/` directory excluded from deployment, but `.claude/CLAUDE.md` individually symlinked to provide environment context while allowing AI tool to manage its own cache/state files
  - **Gemini CLI**: Standard `.config/gemini/` subdirectory management via `.config/.gitignore` inclusion pattern
  - **Dynamic Package Reference**: Both tools reference Devbox global configuration (`~/.local/share/devbox/global/default/devbox.json`) and use commands like `devbox global list` to discover available development tools
  - **Rationale**: This hybrid approach allows AI tools to understand the development environment context while maintaining clean separation between configuration (git-managed) and runtime data (user-specific)

## 2025-XX-XX

- **Deployment Configuration Strategy**: Maintained UNIX-style deployment configuration pattern while eliminating hardcoded values

  **Context**: The repository used CANDIDATES (whitelist) and EXCLUSIONS (blacklist) files for deployment configuration, following classic UNIX patterns similar to rsync and tar. However, PARTIAL_LINKS (nested paths requiring selective symlinking) was hardcoded in the Makefile, creating inconsistency.

  **Initial Proposal**: Replace CANDIDATES/EXCLUSIONS/Makefile logic with a single declarative `deploy.conf` file using INI-style sections ([deploy], [partial], [special]).

  **Actual Decision**: Maintain CANDIDATES/EXCLUSIONS pattern, externalize PARTIAL_LINKS to separate file

  **Rationale for Decision**:
  - **UNIX Philosophy Preservation**: CANDIDATES/EXCLUSIONS follows standard whitelist/blacklist conventions used by rsync, tar, and other UNIX tools
  - **Appropriate Complexity**: The Makefile deployment logic (using `grep`, `tr`, `foreach`, `filter-out`, `wildcard`) is standard text processing expected from Makefile users, not genuinely "complex"
  - **Minimal Real Issue**: Only genuine problem was PARTIAL_LINKS hardcoded in Makefile rather than externalized like other configuration
  - **Consistency Over Simplification**: Three separate configuration files (CANDIDATES, EXCLUSIONS, PARTIAL_LINKS) maintain clear separation of concerns

  **Changes Implemented**:
  - Created `PARTIAL_LINKS` file with same format as CANDIDATES/EXCLUSIONS
  - Updated Makefile to load PARTIAL_LINKS from external file instead of hardcoding
  - Added clear comments documenting deployment configuration flow
  - Current PARTIAL_LINKS: `.local/share/devbox/global/default` (parent `.local` auto-excluded)

  **Configuration Structure**:
  ```
  CANDIDATES      → Whitelist of deployment targets (patterns like .??*, explicit paths)
  EXCLUSIONS      → Blacklist of files to skip (.git, .DS_Store, etc.)
  PARTIAL_LINKS   → Nested paths to symlink individually (parents auto-excluded)
  ```

  **Impact**:
  - Eliminated hardcoded configuration from Makefile
  - Maintained consistency (all deployment config in external files)
  - Preserved UNIX conventions and learning patterns
  - No additional learning curve (same format across all config files)
  - Easy extension (add lines to appropriate file)

  **Alternative Considered**: Consolidating to single `deploy.conf` with INI sections was considered but rejected to maintain UNIX simplicity and avoid introducing new configuration formats.

## 2026-01-02

- **Shell Configuration Cleanup**: Eliminated duplicate settings across shell configuration files while preserving multi-shell support

  **Context**: The repository tracked 7 shell configuration files (`.profile`, `.shellrc`, `.bash_profile`, `.bashrc`, `.zprofile`, `.zshenv`, `.zshrc`) with significant duplication. Settings like Homebrew/Devbox initialization, LANG, EDITOR, and LM Studio PATH were redundantly defined in 3-4 different files, causing maintenance burden and slower shell startup.

  **Initial Proposal**: Delete 6 "legacy" files and keep only minimal `.zshrc` for system compatibility, assuming Fish is the sole interactive shell.

  **Actual Decision**: Remove duplicate settings, NOT files - maintain all 7 shell configuration files

  **Rationale for Decision Change**:
  - **Multi-shell reality**: The environment requires support for three shells with distinct roles:
    - **Zsh**: Login shell (default for SSH connections, security consideration)
    - **Fish**: Interactive shell (launched by iTerm for daily use)
    - **Bash**: Internal shell (used by development tools like Claude Code, script execution)
  - **Cannot consolidate further**: Bash and Zsh require separate configuration files due to incompatible syntax (e.g., `shopt` vs `setopt`, `bind` vs `bindkey`)
  - **Minimum viable set**: 5 files are technically required (`.profile`, `.bash_profile`, `.bashrc`, `.zprofile`, `.zshrc`); `.shellrc` and `.zshenv` provide useful modularization

  **Changes Implemented**:
  - **Duplicate Removal** (8 locations, ~46 lines):
    - `.zshrc`: Removed 6 duplicates (LANG, EDITOR, terminal colors, Homebrew init, Devbox init, LM Studio PATH)
    - `.bashrc`: Removed 1 duplicate (LM Studio PATH)
    - `.bash_profile`: Removed 1 duplicate (LM Studio PATH)
    - All removed settings were already centralized in `.profile` or `.shellrc`
  - **Load Order Optimization**:
    - `.bashrc`: Removed redundant `.profile` sourcing (already loaded by `.bash_profile` during login)
    - `.zshrc`: Removed redundant `.profile` sourcing (already loaded by `.zprofile` during login)

  **Final Configuration Structure** (clear separation of concerns):
  ```
  .profile        → Environment variables (LANG, EDITOR, Homebrew, Devbox, PATH)
                    Sourced by: .bash_profile, .zprofile

  .shellrc        → Common interactive settings (aliases, terminal colors)
                    Sourced by: .bashrc, .zshrc

  .bash_profile   → Bash login shell (sources .profile, conditionally sources .bashrc)
  .bashrc         → Bash interactive shell (Bash-specific: history, keybindings)

  .zprofile       → Zsh login shell (sources .profile)
  .zshenv         → Zsh environment (early init, currently loads .zsh.d/zshenv.*)
  .zshrc          → Zsh interactive shell (Zsh-specific: setopt, compinit, fzf, Docker)
  ```

  **Impact**:
  - Improved shell startup speed (eliminated 8 duplicate initializations)
  - Reduced maintenance burden (single source of truth for common settings)
  - Preserved cross-shell compatibility (Bash/Zsh/Fish all supported)
  - Clearer mental model (each file has a specific, documented purpose)

  **Testing**: Verified Zsh and Bash functionality after changes - all environment variables (LANG, EDITOR), tools (Homebrew, Devbox), and PATH modifications work correctly in both shells.
