#!/bin/bash

echo -e "\e[34mThis script will configure your Ubuntu installation with a baseline of applications. Do not run this script as sudo. This script should only be run on a fresh install of Ubuntu. You can cancel the script within the next 5 seconds\e[0m"
sleep 5

echo -e "\e[34mCurrent user is $USER\e[0m"

if [ "$EUID" -eq 0 ]; then
  echo -e "\e[34mPlease do not run as root\e[0m"
  exit 1
fi

echo -e "\e[34mStarting installation script...\e[0m"

# Update package lists
echo -e "\e[34mUpdating package lists...\e[0m"
sudo apt update

# Install essential packages
echo -e "\e[34mInstalling essential packages...\e[0m"
sudo apt install -y curl wget software-properties-common apt-transport-https gnupg

# Install VSCode
echo -e "\e[34mInstalling Visual Studio Code...\e[0m"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# Install Brave Browser
echo -e "\e[34mInstalling Brave Browser...\e[0m"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# Install Discord
echo -e "\e[34mInstalling Discord...\e[0m"
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
sudo apt install -y ./discord.deb

# Install VLC
echo -e "\e[34mInstalling VLC...\e[0m"
sudo apt install -y vlc

# Install Apache OpenOffice
echo -e "\e[34mInstalling Apache OpenOffice...\e[0m"
wget "https://sourceforge.net/projects/openofficeorg.mirror/files/latest/download" -O openoffice.tar.gz
tar -xvzf openoffice.tar.gz
cd apache-openoffice-*
sudo dpkg -i DEBS/*.deb
sudo dpkg -i DEBS/desktop-integration/*.deb
cd ..

# Install OneDrive
echo -e "\e[34mInstalling OneDrive...\e[0m"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$(lsb_release -rs)/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
sudo apt-get update
sudo apt install -y --no-install-recommends --no-install-suggests onedrive

# Install Obsidian
echo -e "\e[34mInstalling Obsidian...\e[0m"
wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.16/obsidian_1.4.16_amd64.deb
sudo dpkg -i obsidian_1.4.16_amd64.deb

# Install Lutris
echo -e "\e[34mInstalling Lutris...\e[0m"
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt update
sudo apt install -y lutris

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

echo -e "\e[34mInstallation script completed.\e[0m"