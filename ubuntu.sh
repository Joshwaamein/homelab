#!/bin/bash

echo -e "\e[34mThis script will configure your Ubuntu installation with a baseline of applications for Ubuntu 24.04 only. Do not run this script as sudo. This script should only be run on a fresh install of Ubuntu. You can cancel the script within the next 5 seconds\e[0m"
sleep 5

echo -e "\e[34mCurrent user is $USER\e[0m"

if [ "$EUID" -eq 0 ]; then
  echo -e "\e[34mPlease do not run as root\e[0m"
  exit 1https://github.com/Joshwaamein/ubuntu-apps/edit/main/ubuntu.sh
fi

echo -e "\e[34mStarting installation script...\e[0m"

# Update package lists
echo -e "\e[34mUpdating package lists...\e[0m"
sudo apt update

# Install essential packages
echo -e "\e[34mInstalling essential packages...\e[0m"
sudo apt install -y curl wget software-properties-common apt-transport-https gnupg snapd git

# Install VSCode
echo -e "\e[34mInstalling Visual Studio Code...\e[0m"
sudo snap install code --classic

# Install Brave Browser
echo -e "\e[34mInstalling Brave...\e[0m"
sudo snap install brave

# Install Discord
echo -e "\e[34mInstalling Discord...\e[0m"
sudo snap install discord

# Install VLC
echo -e "\e[34mInstalling VLC...\e[0m"
sudo apt install -y vlc

# Install Apache OpenOffice
#echo -e "\e[34mInstalling Apache OpenOffice...\e[0m"
#wget "https://sourceforge.net/projects/openofficeorg.mirror/files/latest/download" -O openoffice.tar.gz
#tar -xvzf openoffice.tar.gz
#cd apache-openoffice-*
#sudo dpkg -i DEBS/*.deb
#sudo dpkg -i DEBS/desktop-integration/*.deb
#cd ..

# Install OneDrive
echo -e "\e[34mInstalling Onedrive...\e[0m"
wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_24.04/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
sudo apt-get update
sudo apt install --no-install-recommends --no-install-suggests onedrive

# Install Obsidian
echo -e "\e[34mInstalling Obsidian...\e[0m"
sudo snap install obsidian --classic

# Install Lutris
echo -e "\e[34mInstalling Lutris...\e[0m"
sudo apt install lutris -y

# Install Steam
echo -e "\e[34mInstalling Steam...\e[0m"
sudo apt install -y steam

# Install Ubuntu Extensions
echo -e "\e[34mInstalling Ubuntu Extensions...\e[0m"
sudo apt install -y gnome-shell-extensions

# Install Private Internet Access
echo -e "\e[34mInstalling Private Internet Access...\e[0m"
wget https://installers.privateinternetaccess.com/download/pia-linux-3.3.1-06924.run
chmod +x pia-linux-3.3.1-06924.run
sudo ./pia-linux-3.3.1-06924.run

# Install Tailscale
echo -e "\e[34mInstalling Tailscale...\e[0m"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt update
sudo apt install -y tailscale

#Install Parsec
echo -e "\e[34mInstalling Parsec...\e[0m"
sudo snap install parsec --classic

#Setting up Dynamic Wallpaper
echo -e "\e[34mInstalling Wallpaper...\e[0m"
curl -s https://wallpapers.manishk.dev/install.sh | bash -s Catalina

# Update firmware
echo -e "\e[34mUpdating firmware...\e[0m"
sudo apt install -y fwupd
sudo fwupdmgr refresh
sudo fwupdmgr update

# Update drivers
echo -e "\e[34mUpdating drivers...\e[0m"
sudo ubuntu-drivers autoinstall

# Clean up
echo -e "\e[34mCleaning up...\e[0m"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

echo -e "\e[34mInstallation script completed.You need to run sudo tailscale up to configure tailscale. You need to start onedrive with onedrive --monitor. You should also set your wallpaper to the dynamic option in settings. \e[0m"
