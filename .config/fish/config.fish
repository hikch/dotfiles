## 
# setup shell
set -x SHELL /opt/homebrew/bin/fish

# setup default editor
set -x EDITOR vi

# setup homebrew
eval (/opt/homebrew/bin/brew shellenv)

# openssl
fish_add_path /opt/homebrew/opt/openssl@1.1/bin

# setup direnv
eval (direnv hook fish)

# setup pyenv
status is-interactive; and pyenv init --path | source
pyenv init - | source

# setup gcloud
# The next line updates PATH for the Google Cloud SDK.
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"

## MySQL
#
set -x PATH /usr/local/mysql/bin $PATH
set -x DYLD_LIBRARY_PATH /usr/local/mysql/lib/

# setup poetry
set -x PATH ~/.poetry/bin $PATH

# pip cache
set -x PIP_DOWNLOAD_CACHE ~/.cache/pip
