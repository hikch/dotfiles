# ~/.config/fish/conf.d/tailscale.fish
# Define the `tailscale` function only if the binary exists.

# Candidate paths (priority: Homebrew → GUI app)
set -l _ts_candidates \
  /opt/homebrew/bin/tailscale \
  /usr/local/bin/tailscale \
  /Applications/Tailscale.app/Contents/MacOS/Tailscale

# Use the first existing executable found
set -l _ts_bin ""
for p in $_ts_candidates
  if test -x $p
    set _ts_bin $p
    break
  end
end

# Define the function only if a binary was found
if test -n "$_ts_bin"
  alias tailscale="$_ts_bin"
end

# Cleanup (local variables are removed automatically, but this is explicit)
set -e _ts_candidates
set -e _ts_bin

