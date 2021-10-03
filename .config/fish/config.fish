## 
# setup shell
set -x SHELL /opt/homebrew/bin/fish

# setup default editor
set -x EDITOR vi

# setup homebrew
test -e /opt/homebrew/bin/brew; and eval (/opt/homebrew/bin/brew shellenv)

# openssl
test -e /opt/homebrew/opt/openssl@1.1/bin; and fish_add_path /opt/homebrew/opt/openssl@1.1/bin

# setup direnv
which direnv > /dev/null; and eval (direnv hook fish)

# setup pyenv
if which pyenv > /dev/null
    status is-interactive; and pyenv init --path | source
    pyenv init - | source
end

# setup gcloud
# The next line updates PATH for the Google Cloud SDK.
if test -e "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"
    source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"
end

# setup poetry
which poetry > /dev/null; and set -x PATH ~/.poetry/bin $PATH

# pip cache
which pip > /dev/null; and set -x PIP_DOWNLOAD_CACHE ~/.cache/pip

# iTerm
test -e /Users/hu/.iterm2_shell_integration.fish ; and source /Users/hu/.iterm2_shell_integration.fish ; or true
