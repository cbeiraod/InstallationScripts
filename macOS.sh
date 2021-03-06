#!/bin/sh
################################################################################
# Author: Cristóvão B. da Cruz e Silva
# Date: 22/12/2017
# Description: This script sets up and installs a basic working system for
#   macOS, according to my preferences.
################################################################################

## Functions
function containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

SUDO=
function defaults_add_to_array () {
  local domain=$1
  local key=$2
  local value=$3

  #echo "Trying to add to domain $domain (key:value):"
  #echo "  - $key:$value"

  local currentList=$($SUDO defaults read "$domain" "$key" | sed '1d;$d' | tr '\n' ' ' | tr -d " ")
  local array
  IFS=',' read -r -a array <<< "$currentList"

  local valueCheck='"'$(echo $value | tr -d " ")'"'

  if containsElement "$valueCheck" "${array[@]}" ; then
    #echo "It is inside"
  else
    #echo "It is not inside"
    $SUDO defaults write "$domain" "$key" -array-add "$value"
  fi
}




################################################################################
# Ask about some general installation options
clear
unset answer
read -t 4 -er -n 1 -p "Is the system installed on an SSD? [Y/n] " answer
[ $? -ne 0 ] && echo "" # Add a new line when it times out
[ -z "$answer" ] && answer="Y" # Yes is the default answer
if echo "$answer" | grep -iq "^y" ;then
  onSSD=1
else
  onSSD=
fi

if [ onSSD -eq 1 ] ; then
  unset answer
  read -t 4 -er -n 1 -p "  Does TRIM force have to be enabled? [y/N] " answer
  [ $? -ne 0 ] && echo "" # Add a new line when it times out
  [ -z "$answer" ] && answer="N" # No is the default answer
  if echo "$answer" | grep -iq "^y" ;then
    enableTRIM=1
  else
    enableTRIM=
  fi
else
  enableTRIM=
fi

clear
unset answer
read -t 4 -er -n 1 -p "Will you use time machine? [Y/n] " answer
[ $? -ne 0 ] && echo "" # Add a new line when it times out
[ -z "$answer" ] && answer="Y" # Yes is the default answer
if echo "$answer" | grep -iq "^y" ;then
  useTimeMachine=1
else
  useTimeMachine=
fi
################################################################################


################################################################################
# Preparing the system
clear
echo "-------------------------------------------------------------------------"
echo "--  Preparing the system"
echo "-------------------------------------------------------------------------"
if [ enableTRIM -eq 1 ] ; then
  echo "Enabling TRIM with trimforce"
  sudo trimforce enable
fi

if [ useTimeMachine -eq 1 ] ; then
  read -n 1 -s -p "Will be using time machine. Please insert the drive to be used as the time machine backup, then press any key to continue"
  sudo tmutil enable
  if [ onSSD -eq 1 ] ; then
    sudo tmutil disablelocal
  fi
fi

if [ onSSD -eq 1 ] ; then
  echo "Disabling hibernation (writing memory to disk on sleep)"
  sudo pmset -a hibernatemode 0
  echo "Removing and locking the sleepimage file"
  sudo rm /Private/var/vm/sleepimage
  sudo touch /Private/var/vm/sleepimage
  sudo chflags uchg /Private/var/vm/sleepimage
  echo ""

  echo "Disabling the sudden motion sensor"
  sudo pmset -a sms 0
  echo ""

  echo "Enabling noatime"
  cat << EOT > noatime.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.particlechaos.noatime</string>
    <key>ProgramArguments</key>
    <array>
      <string>mount</string>
      <string>-vuwo</string>
      <string>noatime</string>
      <string>/</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOT
  sudo chown root:wheel noatime.plist
  sudo mv noatime.plist /Library/LaunchDaemons/com.particlechaos.noatime.plist
  echo ""
fi

echo "Removing some directories from spotlight"
SUDO=sudo defaults_add_to_array /.Spotlight-V100/VolumeConfiguration.plist Exclusions "/Library/Caches"
SUDO=sudo defaults_add_to_array /.Spotlight-V100/VolumeConfiguration.plist Exclusions "~/Library/Caches"
SUDO=sudo defaults_add_to_array /.Spotlight-V100/VolumeConfiguration.plist Exclusions "~/Downloads"
sudo launchctl stop com.apple.metadata.mds
sudo launchctl start com.apple.metadata.mds
echo ""

echo "Other configs"
# Show battery percentage in top bar, then restart the UI
defaults write com.apple.menuextra.battery ShowPercent YES

## Finder Preferences
# Show stuff on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
# Sidebar
defaults write com.apple.finder ShowSidebar 1
# Make the computer visible in the sidebar favorites (do not forget to add the home to the favorites by hand)
/usr/libexec/PlistBuddy -c "set systemitems:VolumesList:0:Visibility AlwaysVisible" ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c "delete systemitems:VolumesList:0:Flags" ~/Library/Preferences/com.apple.sidebarlists.plist
# Show all extensions
defaults write com.apple.finder AppleShowAllExtensions -bool true
# Finder: allow text selection in Quick Look (this does not seem to work anymore)
defaults write com.apple.finder QLEnableTextSelection -bool true

## System Preferences
# Use dark theme
osascript <<END
tell application "System Events"
  tell appearance preferences
    set dark mode to true
  end tell
end tell
END
# Do not close windows when quitting an app (this means that the state is kept)
defaults write -g NSQuitAlwaysKeepsWindows -int 1
# Set Dock size and magnification
defaults write com.apple.dock tilesize -int 32
defaults write com.apple.dock magnification -int 1
defaults write com.apple.dock largesize -int 84
# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
# Group windows by application
defaults write com.apple.dock expose-group-apps -bool true
# Make screens not share spaces
defaults write com.apple.spaces spans-displays -bool false
# Setting hot corners
#   Desktop
defaults write com.apple.dock wvous-bl-corner -int 4
#   Application windows
defaults write com.apple.dock wvous-tl-corner -int 3
#   Mission control
defaults write com.apple.dock wvous-tr-corner -int 2
#   Launch Pad
defaults write com.apple.dock wvous-br-corner -int 11
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-br-modifier -int 0
# Show icon when location services are accessed:
sudo defaults write /Library/Preferences/com.apple.locationmenu ShowSystemServices 1
# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Add bluetooth icon to menu bar
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.bluetooth" -bool true
# Configure clock in menu bar
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"

## Consistency Sanity Checks
# Ensure menu bar is consistent
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Clock.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/Battery.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/AirPort.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/Displays.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/TextInput.menu"
defaults_add_to_array com.apple.systemuiserver menuExtras "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
defaults write com.apple.systemuiserver "NSStatusItem Visible Siri" -bool false
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.TimeMachine" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.airplay" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.airport" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.battery" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.bluetooth" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.clock" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.textinput" -bool true
defaults write com.apple.systemuiserver "__NSEnableTSMDocumentWindowLevel" -bool true
# Ensure trackpad options are consistent
defaults write com.apple.AppleMultitouchTrackpad "ActuateDetents" -int 1
defaults write com.apple.AppleMultitouchTrackpad "Clicking" -bool false
defaults write com.apple.AppleMultitouchTrackpad "DragLock" -bool false
defaults write com.apple.AppleMultitouchTrackpad "Dragging" -bool false
defaults write com.apple.AppleMultitouchTrackpad "FirstClickThreshold" -int 1
defaults write com.apple.AppleMultitouchTrackpad "ForceSuppressed" -bool false
defaults write com.apple.AppleMultitouchTrackpad "SecondClickThreshold" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadCornerSecondaryClick" -int 0
defaults write com.apple.AppleMultitouchTrackpad "TrackpadFiveFingerPinchGesture" -int 2
defaults write com.apple.AppleMultitouchTrackpad "TrackpadFourFingerHorizSwipeGesture" -int 2
defaults write com.apple.AppleMultitouchTrackpad "TrackpadFourFingerPinchGesture" -int 2
defaults write com.apple.AppleMultitouchTrackpad "TrackpadFourFingerVertSwipeGesture" -int 2
defaults write com.apple.AppleMultitouchTrackpad "TrackpadHandResting" -bool true
defaults write com.apple.AppleMultitouchTrackpad "TrackpadHorizScroll" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadMomentumScroll" -bool true
defaults write com.apple.AppleMultitouchTrackpad "TrackpadPinch" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadRightClick" -bool true
defaults write com.apple.AppleMultitouchTrackpad "TrackpadRotate" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadScroll" -bool true
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool true
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerHorizSwipeGesture" -int 0
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerTapGesture" -int 2
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerVertSwipeGesture" -int 0
defaults write com.apple.AppleMultitouchTrackpad "TrackpadTwoFingerDoubleTapGesture" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadTwoFingerFromRightEdgeSwipeGesture" -int 3
defaults write com.apple.AppleMultitouchTrackpad "USBMouseStopsTrackpad" -int 0
defaults write com.apple.AppleMultitouchTrackpad "UserPreferences" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "Clicking" -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "DragLock" -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "Dragging" -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadCornerSecondaryClick" -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadFiveFingerPinchGesture" -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadFourFingerHorizSwipeGesture" -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadFourFingerPinchGesture" -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadFourFingerVertSwipeGesture" -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadHandResting" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadHorizScroll" -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadMomentumScroll" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadPinch" -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadRightClick" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadRotate" -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadScroll" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadThreeFingerDrag" -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadThreeFingerHorizSwipeGesture" -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadThreeFingerTapGesture" -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadThreeFingerVertSwipeGesture" -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadTwoFingerDoubleTapGesture" -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadTwoFingerFromRightEdgeSwipeGesture" -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "USBMouseStopsTrackpad" -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "UserPreferences" -bool true

## Other
# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `Nlsv`, `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
# Disable the “Are you sure you want to open this application?” dialog
#defaults write com.apple.LaunchServices LSQuarantine -bool false

# Restart the guys (maybe not sufficient to update everything)
killall SystemUIServer
killall Finder
killall Dock

## Safari Preferences
# Safari to not open automatically
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
# Do not autofill
defaults write com.apple.Safari "AutoFillCreditCardData" -bool false
defaults write com.apple.Safari "AutoFillFromAddressBook" -bool false
defaults write com.apple.Safari "AutoFillMiscellaneousForms" -bool false
defaults write com.apple.Safari "AutoFillPasswords" -bool false
# Cookies only from current website
defaults write com.apple.Safari "BlockStoragePolicy" -int 3
# Ask websites not to track
defaults write com.apple.Safari "SendDoNotTrackHTTPHeader" -bool true
# Remove requesting for push notifications
defaults write com.apple.Safari "CanPromptForPushNotifications" -bool false
# Show full website address
defaults write com.apple.Safari "ShowFullURLInSmartSearchField" -bool true
# Set up Safari for development
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

## Mail preferences (maybe best to do by hand... ?)

# Unhide/hide folders
#chflags nohidden ~/Library/
#chflags hidden ~/Documents/Secrets

#(some ideas: https://gist.github.com/benfrain/7434600)
echo ""
################################################################################




################################################################################
# Install homebrew, my preferred package manager for mac
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing homebrew"
echo "-------------------------------------------------------------------------"
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
################################################################################


################################################################################
# Install source control software
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing and configuring source control software (git & hg)"
echo "-------------------------------------------------------------------------"
brew install git
brew install hg
# Git configuration below
git config --global user.email "CrisXed@gmail.com"
git config --global user.name "Cristóvão B. da Cruz e Silva"
git config --global core.editor nano
# hg configuration below
cat << EOT > ~/.hgrc
[ui]
username = Cristóvão B. da Cruz e Silva <CrisXed@gmail.com>
editor = nano
EOT
################################################################################


################################################################################
# Install latex
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing Latex"
echo "-------------------------------------------------------------------------"
sudo apt-get install -y texlive texlive-binaries texlive-fonts-recommended \
  texlive-generic-recommended texlive-latex-base texlive-latex-extra \
  texlive-latex-recommended texlive-pictures texlive-latex-extra \
  texlive-luatex texlive-xetex texlive-fonts-extra
sudo apt-get install -y kile texmaker
################################################################################


################################################################################
# Fonts
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing fonts"
echo "-------------------------------------------------------------------------"
sudo apt-get install -y ttf-mscorefonts-installer
sudo apt-get install -y lmodern
# Update for fontspec in latex
rm ~/.texmf-var/luatex-cache/generic/fonts/otf/*
luaotfload-tool -v --update --force
sudo texhash
################################################################################


################################################################################
# Configs
clear
echo "-------------------------------------------------------------------------"
echo "--  Running some miscelanous configurations"
echo "-------------------------------------------------------------------------"
#sudo adduser cristovao vboxsf
################################################################################


################################################################################
# Clean up
clear
echo "-------------------------------------------------------------------------"
echo "--  Cleaning up"
echo "-------------------------------------------------------------------------"
################################################################################


################################################################################
# Info
clear
echo "-------------------------------------------------------------------------"
echo "--  Information"
echo "-------------------------------------------------------------------------"
echo ""
echo "Do not forget to go into System Preferences and, under Language & Region,"
echo "add Portuguese and Japanese as a language, with English as the primary."
echo "Add Japanese as an input source under Keyboard > Input Sources."
echo "Check enabled multitouch gestures for the trackpad and enable 4 fingers."
echo "Check enabled 3 finger swipe."
echo ""
read -n 1 -s -p "Press any key to continue (will restart the machine)"
################################################################################


################################################################################
# Restart the system
clear
echo "-------------------------------------------------------------------------"
echo "--  Restarting"
echo "-------------------------------------------------------------------------"
sleep 20
#sudo shutdown -r now
################################################################################
exit 0


################################################################################
# Description
clear
echo "-------------------------------------------------------------------------"
echo "--  Description"
echo "-------------------------------------------------------------------------"
################################################################################
