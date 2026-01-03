##
# Setup shell
set -gx SHELL $(which fish)

# Setup default editor
set -gx EDITOR vi

# Setup default pager
set -gx PAGER less

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
which poetry > /dev/null; and set -gx PATH ~/.poetry/bin $PATH

# pip cache
which pip > /dev/null; and set -gx PIP_DOWNLOAD_CACHE ~/.cache/pip

# iTerm
test -e /Users/hu/.iterm2_shell_integration.fish ; and source /Users/hu/.iterm2_shell_integration.fish ; or true

# user bin
test -e ~/bin ; and set -gx PATH ~/bin $PATH

# Docker Desktop
source /Users/hu/.docker/init-fish.sh || true # Added by Docker Desktop

# Ollama configuration for Tailscale-only access (client side)
set -gx OLLAMA_HOST "imac-2020:11434"

# Homebrew: ensure PATH and completions
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

if which brew > /dev/null 2>&1
    if test -d (brew --prefix)"/share/fish/completions"
        set -p fish_complete_path (brew --prefix)/share/fish/completions
    end
    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
end

# Devbox
if which devbox > /dev/null 2>&1
    devbox global shellenv --init-hook | source
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/hu/.lmstudio/bin
# End of LM Studio CLI section

