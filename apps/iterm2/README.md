# iTerm2 Configuration

iTerm2 terminal emulator configuration using Dynamic Profiles.

## What are Dynamic Profiles?

Dynamic Profiles allow iTerm2 profiles to be stored in external JSON files instead of the main preferences database. Benefits:

- **Version Control**: Track profile changes in git
- **Hot Reload**: Changes are detected automatically (no restart needed)
- **Portable**: Share profiles across machines easily
- **Clean Separation**: Main plist file (`com.googlecode.iterm2.plist`) can auto-update without conflicts

## Current Profiles

### 00-default.json
- **Name**: Default
- **Font**: Monaco 14
- **Theme**: Solarized Light
- **Features**: Unlimited scrollback, 256-color support

### 10-tmux.json
- **Name**: tmux
- **Inherits**: Default profile
- **Initial Command**: `/opt/homebrew/bin/fish`
- **Features**: Unlimited scrollback, window resizing disabled
- **Use Case**: Terminal sessions within tmux

## Deployment

### Initial Setup

```bash
make iterm2-profiles
```

This copies JSON files to `~/Library/Application Support/iTerm2/DynamicProfiles/`.

### Updating Profiles

1. Edit JSON files in `apps/iterm2/profiles/`
2. Run `make iterm2-profiles`
3. iTerm2 automatically reloads (no restart required)

Changes appear instantly in iTerm2 Preferences → Profiles.

## Exporting Profiles from iTerm2 UI

To capture complete profile settings:

1. Open iTerm2 → Preferences → Profiles
2. Select profile
3. Right-click → Other Actions → Copy Profile as JSON
4. Paste into corresponding JSON file
5. Commit to git

## Profile Format

### Minimal Profile

```json
{
  "Profiles": [
    {
      "Name": "ProfileName",
      "Guid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
      "Normal Font": "Monaco 14",
      "Terminal Type": "xterm-256color"
    }
  ]
}
```

### Inheriting from Parent

```json
{
  "Profiles": [
    {
      "Name": "ChildProfile",
      "Guid": "UNIQUE-GUID-HERE",
      "Dynamic Profile Parent Name": "Default",
      "Initial Text": "echo 'custom command'"
    }
  ]
}
```

## File Naming Convention

- **00-xxx.json**: Parent profiles (loaded first)
- **10-xxx.json**: Child profiles (loaded after parents)
- Numeric prefix ensures correct load order

## GUIDs

Each profile needs a unique GUID. Generate with:

```bash
uuidgen
```

Keep existing GUIDs when migrating profiles to maintain iTerm2's default profile selection.

## Troubleshooting

### Profiles not appearing

1. Check JSON syntax: `python3 -m json.tool < 00-default.json`
2. Verify file location: `ls ~/Library/Application\ Support/iTerm2/DynamicProfiles/`
3. Check Console.app for iTerm2 errors

### Profiles show as "Dynamic" prefix

This is normal. Dynamic Profiles are labeled to distinguish them from manually-created profiles.

### Changes not reloading

1. Verify file was copied: `make iterm2-profiles`
2. Check file modification time
3. Restart iTerm2 as last resort

## See Also

- [iTerm2 Dynamic Profiles Documentation](https://iterm2.com/documentation-dynamic-profiles.html)
- [apps/ README](../README.md) - Overall apps directory structure
