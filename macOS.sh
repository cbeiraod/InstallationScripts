#!/bin/sh
################################################################################
# Author: Cristóvão B. da Cruz e Silva
# Date: 22/12/2017
# Description: This script sets up and installs a basic working system for
#   macOS, according to my preferences.
################################################################################




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
sudo defaults write /.Spotlight-V100/VolumeConfiguration.plist Exclusions -array-add "/Library/Caches"
sudo defaults write /.Spotlight-V100/VolumeConfiguration.plist Exclusions -array-add "~/Library/Caches"
sudo defaults write /.Spotlight-V100/VolumeConfiguration.plist Exclusions -array-add "~/Downloads"
sudo launchctl stop com.apple.metadata.mds
sudo launchctl start com.apple.metadata.mds
echo ""

echo "Other configs"
# Show battery percentage in top bar, then restart the UI
defaults write com.apple.menuextra.battery ShowPercent YES
killall SystemUIServer

## Finder
# Show stuff on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop 1
defaults write com.apple.finder ShowHardDrivesOnDesktop 1
defaults write com.apple.finder ShowMountedServersOnDesktop 1
defaults write com.apple.finder ShowRemovableMediaOnDesktop 1
# Sidebar
defaults write com.apple.finder ShowSidebar 1
# Make the computer visible in the sidebar favorites (do not forget to add the home to the favorites by hand)
/usr/libexec/PlistBuddy -c "set systemitems:VolumesList:0:Visibility AlwaysVisible" ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c "delete systemitems:VolumesList:0:Flags" ~/Library/Preferences/com.apple.sidebarlists.plist
# Show all extensions
defaults write com.apple.finder AppleShowAllExtensions 1
killall Finder
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
# hg configuration below

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
