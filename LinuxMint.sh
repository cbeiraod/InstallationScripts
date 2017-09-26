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
sudo apt-get install -y msttcorefonts
sudo apt-get install -y ttf-mscorefonts-extra
sudo apt-get install -y lmodern
# Update for fontspec in latex
#luaotfload-tool -vvv --update --force
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
sleep 60
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
