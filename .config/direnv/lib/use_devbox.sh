#!/usr/bin/env bash
# use_devbox.sh - direnv integration for devbox
# Usage in .envrc: use devbox

use_devbox() {
    local project_root="${1:-$PWD}"
    
    # Check if devbox is available
    if ! command -v devbox >/dev/null 2>&1; then
        log_error "devbox command not found. Please install devbox first."
        return 1
    fi
    
    # Load devbox environment using devbox's built-in direnv integration
    eval "$(devbox shellenv --init-hook --install --no-refresh-alias)"
    
    # Ensure ~/bin is in PATH (matching sukebei/.envrc pattern)
    if [ -d "$HOME/bin" ]; then
        export PATH="$HOME/bin:$PATH"
    fi
}
