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
