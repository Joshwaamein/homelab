# 🐧 Linux Scripts

Linux/Ubuntu utility scripts for homelab setup and management.

## 📋 Available Scripts

### setup-ssh-key-on-remote-host.sh (v2.0)

**Professional SSH key deployment script with safety checks.**

- Generates ed25519 SSH key if not exists
- Copies SSH key to remote and root users
- Backs up and hardens sshd_config
- Verifies key auth works before disabling passwords

```bash
./setup-ssh-key-on-remote-host.sh <remote_host> <remote_user>
```

**Prerequisites:** `sshpass`, `openssh-client`

---

### deploy-zsh-setup.sh (v2.0)

**Complete zsh environment deployment script.**

- Installs zsh, Oh My Zsh, plugins, and fzf
- Optionally installs NVM and AWS CLI
- Deploys professional .zshrc with aliases and functions

```bash
sudo ./deploy-zsh-setup.sh
sudo ./deploy-zsh-setup.sh --user noble --theme agnoster
```

---

### zabbixdeploy.sh (v2.0)

**Production-grade Zabbix agent installation script.**

- Downloads and verifies Zabbix agent
- Creates system user with proper permissions
- Configures systemd service with security hardening

```bash
sudo ./zabbixdeploy.sh
sudo ./zabbixdeploy.sh --server YOUR_ZABBIX_IP --version 7.2.4
```

---

### unattended-upgrades.sh

**Automated unattended upgrades configuration for Ubuntu servers.**

Configures automatic security patches and package updates without manual intervention.

- Installs and configures unattended-upgrades package
- Automatic security and system package updates
- Scheduled automatic reboots at 1 AM if required
- Distribution upgrades and kernel updates excluded
- Unused dependencies automatically removed
- Daily cron job for upgrades

```bash
# Run directly
sudo ./unattended-upgrades.sh

# Or via curl
curl -sSL https://raw.githubusercontent.com/Joshwaamein/homelab/main/scripts/linux/unattended-upgrades.sh | bash
```

**Verify configuration:**
```bash
sudo unattended-upgrades --dry-run --debug
```

---

### ubuntu-apps.sh

**Ubuntu desktop application installation automation.**

Automates the installation of essential applications on a fresh Ubuntu desktop using apt and dpkg where possible.

**Applications installed:**
- Visual Studio Code, Brave Browser, Discord
- VLC Media Player, Apache OpenOffice, Obsidian
- OneDrive, Tailscale, Private Internet Access
- Lutris, Steam, Ubuntu Extensions
- Firmware and driver updates via fwupd and ubuntu-drivers

```bash
# Run directly
./ubuntu-apps.sh

# Or via curl (do NOT run with sudo)
curl -sSL https://raw.githubusercontent.com/Joshwaamein/homelab/main/scripts/linux/ubuntu-apps.sh | bash
```

**Prerequisites:** Ubuntu-based distribution, sudo privileges

---

### fix-update-issues.sh

**Fix common apt update issues on Ubuntu/Debian systems.**

```bash
sudo ./fix-update-issues.sh
```

---

## 🚀 Making Scripts Executable

```bash
cd scripts/linux/
chmod +x *.sh
```
