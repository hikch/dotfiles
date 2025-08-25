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