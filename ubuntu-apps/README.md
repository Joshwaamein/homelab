# Ubuntu Application Installation Script

## Overview

This script automates the installation of various applications and tools on Ubuntu-based systems. It uses apt packages and dpkg where possible, minimizing the use of Flatpak.

## Applications Installed

- Visual Studio Code
- Brave Browser
- Discord
- VLC Media Player
- Apache OpenOffice
- OneDrive
- Obsidian
- Lutris
- Steam
- Ubuntu Extensions
- Private Internet Access
- Tailscale

## Additional Actions

- Updates firmware using fwupd
- Updates drivers using ubuntu-drivers

## Prerequisites

- Ubuntu-based Linux distribution
- Sudo privileges

## Usage

Download the script and pipe to bash. Do not run the script with Sudo.
curl -sSL https://raw.githubusercontent.com/Joshwaamein/ubuntu-apps/main/ubuntu.sh | bash
