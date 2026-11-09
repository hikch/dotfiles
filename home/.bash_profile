# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/hu/.docker/bin"
# End of Docker Desktop section.

# Bash login configuration

# Source POSIX profile (shared)
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# For interactive shells, also source .bashrc
case $- in
  *i*) [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" ;;
esac
