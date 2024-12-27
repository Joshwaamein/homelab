#!/bin/bash

echo "This script will configure your Ubuntu installation with a baseline of applications. Do not run this script as sudo. This script should only be run on a fresh install of Ubuntu. You can cancel the script within the next 5 seconds"
sleep 5

echo "Current user is $USER"

if [ "$EUID" -eq 0 ]; then
  echo "Please do not run as root"
  exit 1
fi

# vscode, brave, discord, vlc. apacheoffice, onedrived, discord, obsidian, ledgerlive, lutris, steam, ubuntu extensions, private internet access, taailscale, update all firmawre and drivers

echo "Starting installation script..."

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install essential packages
echo "Installing essential packages..."
sudo apt install -y curl wget software-properties-common apt-transport-https gnupg

# Install VSCode
echo "Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# Install Brave Browser
echo "Installing Brave Browser..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# Install Discord
echo "Installing Discord..."
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
sudo apt install -y ./discord.deb

# Install VLC
echo "Installing VLC..."
sudo apt install -y vlc

# Install Apache OpenOffice
echo "Installing Apache OpenOffice..."
wget "https://sourceforge.net/projects/openofficeorg.mirror/files/latest/download" -O openoffice.tar.gz
tar -xvzf openoffice.tar.gz
cd apache-openoffice-*
sudo dpkg -i DEBS/*.deb
sudo dpkg -i DEBS/desktop-integration/*.deb
cd ..

# Install OneDrive
echo "Installing OneDrive..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$(lsb_release -rs)/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
sudo apt-get update
sudo apt install -y --no-install-recommends --no-install-suggests onedrive

# Install Obsidian
echo "Installing Obsidian..."
wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.16/obsidian_1.4.16_amd64.deb
sudo dpkg -i obsidian_1.4.16_amd64.deb

# Install Lutris
echo "Installing Lutris..."
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt update
sudo apt install -y lutris

# Install Steam
echo "Installing Steam..."
sudo apt install -y steam

# Install Ubuntu Extensions
echo "Installing Ubuntu Extensions..."
sudo apt install -y gnome-shell-extensions

# Install Private Internet Access
echo "Installing Private Internet Access..."
wget https://installers.privateinternetaccess.com/download/pia-linux-3.3.1-06924.run
chmod +x pia-linux-3.3.1-06924.run
sudo ./pia-linux-3.3.1-06924.run

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt update
sudo apt install -y tailscale

# Update firmware
echo "Updating firmware..."
sudo apt install -y fwupd
sudo fwupdmgr refresh
sudo fwupdmgr update

# Update drivers
echo "Updating drivers..."
sudo ubuntu-drivers autoinstall

# Clean up
echo "Cleaning up..."
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

echo "Installation script completed."
