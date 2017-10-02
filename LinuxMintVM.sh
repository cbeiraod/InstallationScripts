#!/bin/sh
################################################################################
# Author: Cristóvão B. da Cruz e Silva
# Date: 26/09/2017
# Description: This script sets up and installs a basic working system for
#   Linux Mint, according to my preferences.
################################################################################




################################################################################
# Ask about some general installation options
clear
unset answer
read -t 4 -er -n 1 -p "Do you wish to install java? [Y/n] " answer
[ $? -ne 0 ] && echo "" # Add a new line when it times out
[ -z "$answer" ] && answer="N" # No is the default answer
if echo "$answer" | grep -iq "^y" ;then
  installJava=1
else
  installJava=
fi
################################################################################


################################################################################
# Add additional repositories for desired packages
if [ installJava -eq 1 ] ; then
  sudo add-apt-repository ppa:webupd8team/java
fi
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
# Install command line Dconf editor
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing the dconf-cli so we can edit options from the command line"
echo "-------------------------------------------------------------------------"
sudo apt-get install -y dconf-cli
################################################################################


################################################################################
# Install some other useful utilities
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing utilities"
echo "-------------------------------------------------------------------------"
  # This one helps us set certificates for firefox via the command line
sudo apt-get install -y libnss3-tools
################################################################################


################################################################################
# Install Keepass, for all my password needs
clear
echo "-------------------------------------------------------------------------"
echo "--  Installing keepassx"
echo "-------------------------------------------------------------------------"
sudo apt-get install -y keepassx
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
# Install java
if [ installJava -eq 1 ] ; then
  clear
  echo "-------------------------------------------------------------------------"
  echo "--  Installing the oracle Java plugin"
  echo "-------------------------------------------------------------------------"
  apt-get remove openjdk*
  sudo apt-get install -y oracle-java9-installer
  sudo apt-get install -y oracle-java9-set-default

  # The following lines seem to not be needed anymore with java 9...
  # At least it is not supported by firefox since version 52 or so
  #mkdir -p ~/.mozzila/plugins
  #ln -s /usr/lib/jvm/java-9-oracle/lib/libnpjp2.so ~/.mozzila/plugins/
fi
################################################################################


################################################################################
# Configs
clear
echo "-------------------------------------------------------------------------"
echo "--  Running some miscelanous configurations"
echo "-------------------------------------------------------------------------"
# Allow the base user to mount virtualbox shared folders
#sudo adduser cristovao vboxsf
# Add the CERN certification authorities to firefox, first get them, then install them
wget https://cafiles.cern.ch/cafiles/certificates/CERN%20Root%20Certification%20Authority%202.crt
wget https://cafiles.cern.ch/cafiles/certificates/CERN%20Certification%20Authority.crt
for certDB in $(find  ~/.mozilla* ~/.thunderbird -name "cert8.db")
do
  certDir=$(dirname ${certDB});
  certutil -A -n "CERN Root Certification Authority" -t "CT,c,C" -i "CERN Root Certification Authority 2.crt" -d ${certDir}
  certutil -A -n "CERN Certification Authority" -t "CT,c,C" -i "CERN Certification Authority.crt" -d ${certDir}
done
################################################################################


################################################################################
# Clean up
clear
echo "-------------------------------------------------------------------------"
echo "--  Cleaning up"
echo "-------------------------------------------------------------------------"
sudo apt-get autoremove
sudo apt-get clean
################################################################################


################################################################################
# Restart the system
clear
echo "-------------------------------------------------------------------------"
echo "--  Restarting"
echo "-------------------------------------------------------------------------"
sleep 20
sudo shutdown -r now
################################################################################
exit 0


################################################################################
# Description
clear
echo "-------------------------------------------------------------------------"
echo "--  Description"
echo "-------------------------------------------------------------------------"
################################################################################
