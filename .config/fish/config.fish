## 
# setup default editor
set -x EDITOR vi

# setup direnv
eval (direnv hook fish)

# setup pyenv
status --is-interactive; and source (pyenv init -|psub)

# setup gcloud
# The next line updates PATH for the Google Cloud SDK.
source /Users/hu/google-cloud-sdk/path.fish.inc

# setup homebrew
eval (/opt/homebrew/bin/brew shellenv)

## MySQL
#
set -x PATH /usr/local/mysql/bin $PATH
set -x DYLD_LIBRARY_PATH /usr/local/mysql/lib/

# setup poetry
set -x PATH ~/.poetry/bin $PATH

# pip cache
set -x PIP_DOWNLOAD_CACHE ~/.cache/pip
