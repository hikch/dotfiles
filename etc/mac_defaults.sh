#! /bin/sh

##
## Common Settings
##

# 全ての拡張子のファイルを表示する
defaults write NSGlobalDomain AppleShowAllExtensions -bool true


##
## Dock
##
#  Changed the position of the Dock to the right side
defaults write com.apple.dock orientation -string "right"

# TODO: Change the application registered in the dock
# defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
#

killall Dock

##
## Finder
##
# TODO: Sidebar settings (not sure what key to set)

# Show home directory in new Finder window
defaults write "com.apple.finder" "NewWindowTargetPath" -string "file://$HOME/"
defaults write "com.apple.finder" "NewWindowTarget" -string "PfHm"

# Items to display on the desktop
defaults write "com.apple.finder" "ShowMountedServersOnDesktop" -bool False
defaults write "com.apple.finder" "ShowRemovableMediaOnDesktop" -bool False
defaults write "com.apple.finder" "ShowHardDrivesOnDesktop" -bool False
defaults write "com.apple.finder" "ShowExternalHardDrivesOnDesktop" -bool False

# When executing a search:
defaults write "com.apple.finder" "FXDefaultSearchScope" -string "SCcf"

# Always display folders at the top of the list in windows sorted by name
defaults write "com.apple.finder" "_FXSortFoldersFirst" -bool True

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show tab bar
defaults write com.apple.finder ShowTabView -bool true

killall Finder

##
## Safari
##

# Enable develop/debug menu
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Show status bar
defaults write com.apple.Safari ShowStatusBar -bool true

##
## Shortcuts
##

# Change previous input source selection to Command-Space
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 60 "
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>1048576</integer>
      </array>
    </dict>
  </dict>
"

# Change Show Spotlight Search to Option-Space
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 64 "
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>524288</integer>
      </array>
    </dict>
  </dict>
  "

# Enable shortcut changes
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u


##
## Other Settings
##

# .DS_Store is not created in a networked directory.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
