# Bash login configuration

# Source POSIX profile (shared)
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# For interactive shells, also source .bashrc
case $- in
  *i*) [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" ;;
esac
