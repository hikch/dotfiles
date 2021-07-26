# setup default editor
export EDITOR=vi

# setup direnv
eval (direnv hook fish)

# setup pyenv
status is-interactive; and pyenv init --path | source
pyenv init - | source
