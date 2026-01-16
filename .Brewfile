# ==========================================
# .Brewfile (common / the single source of truth)
# ==========================================

cask_args appdir: "/Applications"

# Common taps
tap "homebrew/bundle"
tap "homebrew/services"

# Common formulae
# mas moved to Devbox global
# syncthing CLI moved to host-specific (iMac only)
cask "codex"
brew "ollama"

# Common casks
cask "alfred"
cask "appcleaner"
cask "deepl"
cask "discord"
cask "docker-desktop"
cask "dropbox"
cask "evernote"
cask "firefox"
cask "font-menlo-for-powerline"
cask "google-chrome"
cask "gcloud-cli"
cask "google-drive"
cask "hazel"
cask "intellij-idea-ce"
cask "iterm2"
cask "keycastr"
cask "macvim-app"
cask "obsidian"
cask "omnifocus"
cask "omnigraffle"
cask "omnioutliner"
cask "pycharm-ce"
cask "sourcetree"
cask "vlc"
cask "zoom"

# --- Host include ---
host = `hostname`.strip.split(".").first
hostfile = File.expand_path("hosts/#{host}.Brewfile", __dir__)
instance_eval(File.read(hostfile), hostfile) if File.exist?(hostfile)

# --- Local override (not in Git) ---
localfile = File.expand_path(".Brewfile.local", __dir__)
instance_eval(File.read(localfile), localfile) if File.exist?(localfile)
