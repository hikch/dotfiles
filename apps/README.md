# GUI Applications Configuration

This directory contains configuration files for macOS GUI applications.

## Directory Structure

```
apps/
├── iterm2/         # iTerm2 terminal emulator
│   ├── profiles/   # Dynamic Profiles (JSON format)
│   └── README.md
├── terminal/       # Terminal.app (built-in macOS terminal)
│   └── *.terminal  # Color schemes and themes
└── README.md       # This file
```

## Why `apps/` Instead of `.config/`?

This repository follows a clear separation of concerns:

- **`.config/`** - XDG-compliant CLI/development tool configurations
  - Examples: fish (shell), gemini (AI tool), git (version control)
  - Typically symlinked to `$HOME/.config/`

- **`apps/`** - macOS GUI application preferences
  - Examples: iTerm2, Terminal.app, Safari
  - Often deployed to `~/Library/Application Support/` or similar
  - Contains plist files, JSON configs, themes

- **`etc/`** - System-wide macOS configuration scripts
  - Examples: mac_defaults.sh, pmset_settings.sh
  - Shell scripts that apply system settings via `defaults write`

## Deployment

### iTerm2 Profiles

```bash
make iterm2-profiles
```

This copies Dynamic Profile JSON files to `~/Library/Application Support/iTerm2/DynamicProfiles/`.
iTerm2 automatically detects and loads changes without restart.

### Terminal.app Themes

Import manually via Terminal.app:
1. Open Terminal.app → Preferences → Profiles
2. Click gear icon → Import...
3. Select theme file from `apps/terminal/`

## Adding New Applications

To add configuration for a new GUI application:

1. Create subdirectory: `apps/myapp/`
2. Add configuration files
3. Add README.md explaining:
   - What files are included
   - How to deploy them
   - Any manual steps required
4. (Optional) Add Makefile target for automated deployment

## See Also

- [Main README](../README.md) - Overall repository documentation
- [iTerm2 Documentation](iterm2/README.md) - iTerm2-specific details
