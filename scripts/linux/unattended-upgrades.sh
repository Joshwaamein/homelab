#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Install unattended-upgrades
apt update
apt install -y unattended-upgrades

# Create and configure 50unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOL
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}:\${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {
    "linux-image-generic";
    "linux-headers-generic";
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "01:00";
EOL

# Create and configure 20auto-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

# Add cron job for daily upgrades
(crontab -l 2>/dev/null; echo "0 1 * * * /usr/bin/unattended-upgrade -d") | crontab -

# Restart unattended-upgrades service
systemctl restart unattended-upgrades

echo "Unattended upgrades have been configured with automatic reboots at 1 AM if required."
echo "Distribution upgrades are explicitly disabled."
echo "You can verify the configuration by running: sudo unattended-upgrades --dry-run --debug"
