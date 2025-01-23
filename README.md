# Unattended Upgrades Setup Script for Ubuntu

This script configures unattended upgrades and automatic reboots on Ubuntu servers. It ensures your system receives regular package updates and security patches without performing distribution upgrades.

## Features

- Installs and configures unattended-upgrades
- Sets up automatic updates for system and apt packages
- Configures automatic reboots at 1 AM if required
- Excludes distribution upgrades and kernel updates
- Removes unused dependencies
- Sets up a daily cron job for upgrades

## Usage

1. Open a terminal on your Ubuntu server.

2. Run the following command to download and execute the script:

curl -sSL https://raw.githubusercontent.com/Joshwaamein/custom-zsh/main/ubuntu-gnome-terminal.sh | bash

3. The script will run and configure unattended upgrades on your system.

## What the Script Does

1. Checks if it's run with root privileges
2. Installs the unattended-upgrades package
3. Creates and configures `/etc/apt/apt.conf.d/50unattended-upgrades`
4. Creates and configures `/etc/apt/apt.conf.d/20auto-upgrades`
5. Adds a cron job for daily upgrades at 1 AM
6. Restarts the unattended-upgrades service

## Configuration Details

- Updates are allowed from the main Ubuntu repositories and security updates
- Distribution upgrades are explicitly disabled
- Kernel packages are blacklisted to prevent inadvertent major system changes
- Automatic reboots are scheduled for 1 AM if required
- Unused dependencies are automatically removed

## Verification

After running the script, you can verify the configuration by running:

sudo unattended-upgrades --dry-run --debug
