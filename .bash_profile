# Bash login configuration

# Source POSIX profile (shared)
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# For interactive shells, also source .bashrc
case $- in
  *i*) [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" ;;
esac


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/hu/.lmstudio/bin"
# End of LM Studio CLI section

