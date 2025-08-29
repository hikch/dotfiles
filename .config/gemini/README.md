# Gemini CLI Configuration

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