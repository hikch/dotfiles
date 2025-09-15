# Bash interactive configuration

# Load shared login profile and shell settings
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
[ -f "$HOME/.shellrc" ] && . "$HOME/.shellrc"

# History configuration (rough parity with zsh settings)
HISTFILE=$HOME/.bash_history
HISTSIZE=50000
HISTFILESIZE=50000
shopt -s histappend

# Keybindings: emacs style (default) and history search with Up/Down
set -o emacs
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

