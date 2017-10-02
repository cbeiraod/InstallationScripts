#!/bin/sh
################################################################################
# Author: Cristóvão B. da Cruz e Silva
# Date: 26/09/2017
# Description: This script sets up and installs a basic working system for
#   Linux Mint, according to my preferences.
################################################################################




################################################################################
# Update the repositories and then upgrade the locally installed software
# The -y skips confirmation by assuming a positive answer
clear
echo "-------------------------------------------------------------------------"
echo "--  Updating repositories and system"
echo "-------------------------------------------------------------------------"
sudo apt update -y
sudo apt upgrade -y
################################################################################


################################################################################
# Dconf editor
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing the dconf-cli so we can edit options from the command line"
echo "-------------------------------------------------------------------------"
sudo apt-get install dconf-cli
################################################################################


################################################################################
# Install git so we can do source control
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing and configuring git"
echo "-------------------------------------------------------------------------"
sudo apt-get install -y git
# Git configuration below
git config --global user.email "CrisXed@gmail.com"
git config --global user.name "Cristóvão B. da Cruz e Silva"
################################################################################


################################################################################
# Install latex
clear
unset latexInstalled
unset answer
read -t 4 -er -n 1 -p "Do you wish to install latex? [Y/n] " answer
[ $? -ne 0 ] && echo "" # Add a new line when it times out
[ -z "$answer" ] && answer="Y" # Yes is the default answer
if echo "$answer" | grep -iq "^y" ;then
  echo "-------------------------------------------------------------------------"
  echo "--  Installing Latex"
  echo "-------------------------------------------------------------------------"
  sudo apt-get install -y texlive texlive-binaries texlive-fonts-recommended \
    texlive-generic-recommended texlive-latex-base texlive-latex-extra \
    texlive-latex-recommended texlive-pictures texlive-latex-extra \
    texlive-luatex texlive-xetex texlive-fonts-extra
  sudo apt-get install -y kile texmaker
  latexInstalled=1
else
  echo "Skipping latex installation"
  latexInstalled=
fi
################################################################################


################################################################################
# Fonts
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing fonts"
echo "-------------------------------------------------------------------------"
if [ latexInstalled -eq 1 ] ; then
  #   For now, these fonts are only used in my latex scripts, so no need to
  # install them without latex
  sudo apt-get install -y ttf-mscorefonts-installer
  sudo apt-get install -y lmodern
  # Update for fontspec in latex
  rm ~/.texmf-var/luatex-cache/generic/fonts/otf/*
  luaotfload-tool -v --update --force
  sudo texhash
fi
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
sudo apt-get clean
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
