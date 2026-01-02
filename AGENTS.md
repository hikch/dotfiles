# Repository Guidelines

## Available Development Environment

This environment uses Devbox for global package management. To see the current list of available tools and packages, check the Devbox configuration file:

**Devbox Global Configuration:**
- File: `~/.local/share/devbox/global/default/devbox.json`
- Command: `devbox global list` - Shows currently installed packages
- Command: `which <tool>` - Verify if a specific tool is available

**Common Package Categories:**
- Development tools (nodejs, uv, gh)
- System utilities (fish, fzf, ripgrep, jq, tree, tmux)
- Text processing (pandoc, ffmpeg)
- Version control (mercurial)
- AI tools (claude-code, gemini-cli)
- macOS tools (mas)

Always verify tool availability before use, as the package list may change over time.

## Project Structure & Module Organization
- Root: make-driven dotfiles repo for macOS/Linux setup.
- `bin/`: helper scripts added to PATH.
- `etc/`: system setup scripts (e.g., `mac_defaults.sh`).
- `hosts/`: host-specific Homebrew bundles like `$(hostname -s).Brewfile`.
- `.Brewfile`, `.Brewfile.local`: common GUI apps and local overrides.
- `.config/`: not tracked by git by default; opt-in via `.gitignore` edits.
- Control deployment via `CANDIDATES` (whitelist), `EXCLUSIONS` (ignore), and `PARTIAL_LINKS` (nested paths).

## Build, Test, and Development Commands
- `make help`: list available tasks.
- `make deploy`: symlink managed files into `$HOME` (idempotent); fixes `~/.ssh` perms.
- `make init`: first-time setup (Devbox, Homebrew, Fish, macOS defaults).
- `make homebrew` / `make brew/*`: manage packages via Brewfile(s).
- `make vim` / `make fish`: install editor/shell plugins.
- Tip: Dry-run deploy in a sandbox: `HOME=$(mktemp -d) make deploy`.

## Coding Style & Naming Conventions
- Shell: prefer POSIX `sh` for portability; guard scripts with `set -eu` when safe.
- Makefile: use tabs for recipes; keep targets descriptive (e.g., `brew/upgrade`).
- Brewfiles: name host files exactly `hosts/<hostname>.Brewfile`.
- Paths: keep repo‑relative paths; symlink targets live under repo root.

## Testing Guidelines
- Validate changes with `make help`, `make deploy` (sandboxed), and `make brew/check`.
- For host logic, test using a stub: `HOST=$(hostname -s) make brew/setup`.
- Keep deployments reversible; avoid destructive operations in default targets.

## Commit & Pull Request Guidelines
- Commits: imperative, concise, scoped. Examples: `brew: add jq`, `deploy: skip .config`.
- Conventional prefixes welcome (`docs:`, `feat:`, `fix:`) when clear.
- PRs: include purpose, summary of changes, affected hosts, and any manual steps (`reboot`, `brew services`).
- Link issues/ADRs when relevant; add screenshots for macOS settings only if UI changes are shown.

## Security & Configuration Tips
- Never commit secrets; exclude private files via `EXCLUSIONS`.
- `~/.config` is opt-in: explicitly include only what you intend to manage.
- Follow the package policy: CLI tools via Devbox; GUI apps via Homebrew Cask; long‑running daemons via `brew services`.
