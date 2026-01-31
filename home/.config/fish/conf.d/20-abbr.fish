# Fish Abbreviations
# Managed explicitly instead of Universal Variables

# Homebrew tools
abbr -a --global brew /opt/homebrew/bin/brew
abbr -a --global mas /opt/homebrew/bin/mas
abbr -a --global xq /opt/homebrew/bin/xq

# Development tools
abbr -a --global ocaml 'rlwrap ocaml'

abbr -a --global cinit 'git clone --depth 1 https://github.com/hikch/claude-code-orchestra.git .starter && cp -r .starter/.claude .starter/.codex .starter/.gemini .starter/CLAUDE.md . && rm -rf .starter && claude'
