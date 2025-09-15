# POSIX login profile (shared by zsh and bash)

# Locale
if [ "$(id -u)" -eq 0 ]; then
  export LANG=C
else
  export LANG=ja_JP.UTF-8
fi

# Editor
export EDITOR=/usr/bin/vi

# Initialize Homebrew in login shells (Apple Silicon/Intel)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$({ /opt/homebrew/bin/brew shellenv; } 2>/dev/null)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$({ /usr/local/bin/brew shellenv; } 2>/dev/null)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Devbox global shellenv (if installed)
if command -v devbox >/dev/null 2>&1; then
  eval "$(devbox global shellenv --init-hook)"
fi

