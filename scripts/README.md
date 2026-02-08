# 🔧 Utility Scripts

This directory contains production-ready utility scripts for homelab management and setup.

## 📋 Available Scripts

### setup-ssh-key-on-remote-host.sh (v2.0)
**Professional SSH key deployment script with safety checks.**

**What it does:**
- ✅ Generates ed25519 SSH key if not exists
- ✅ Copies SSH key to remote user
- ✅ Copies key to root user with proper sudo
- ✅ **Backs up remote sshd_config before changes**
- ✅ **Verifies SSH key works before disabling passwords**
- ✅ Configures SSH securely (disables password auth)
- ✅ Comprehensive error handling and validation
- ✅ Color-coded output and logging
- ✅ User confirmation before disabling passwords

**Usage:**
```bash
./setup-ssh-key-on-remote-host.sh <remote_host> <remote_user>

# Examples:
./setup-ssh-key-on-remote-host.sh 192.168.1.100 ubuntu
./setup-ssh-key-on-remote-host.sh server1.local admin

# Custom SSH key path:
SSH_KEY=~/.ssh/mykey ./setup-ssh-key-on-remote-host.sh 192.168.1.100 ubuntu
```

**Features:**
- Dependency checking (sshpass, ssh-keygen, etc.)
- Host reachability verification
- Multiple backups of sshd_config
- SSH key authentication verification
- Root access setup with validation
- User confirmation before dangerous operations
- Detailed completion info with next steps

**Prerequisites:**
- `sshpass` installed: `sudo apt install sshpass openssh-client`
- Password for remote user
- Remote host accessible via SSH
- Sudo privileges on remote host

---

### deploy-zsh-setup.sh (v2.0)
**Complete zsh environment deployment script.**

**What it does:**
- ✅ Installs zsh shell
- ✅ Installs Oh My Zsh framework
- ✅ Installs useful plugins (syntax-highlighting, autosuggestions)
- ✅ Installs fzf (fuzzy finder)
- ✅ Optionally installs NVM (Node Version Manager)
- ✅ Optionally installs AWS CLI
- ✅ Deploys improved .zshrc with professional aliases and functions
- ✅ Backs up existing configuration
- ✅ Changes default shell to zsh

**Usage:**
```bash
# Basic usage (current user)
sudo ./deploy-zsh-setup.sh

# For specific user
sudo ./deploy-zsh-setup.sh --user noble

# With custom theme
sudo ./deploy-zsh-setup.sh --theme agnoster

# With AWS CLI
sudo ./deploy-zsh-setup.sh --install-aws-cli

# Minimal install (no fun packages)
sudo ./deploy-zsh-setup.sh --minimal

# Show help
./deploy-zsh-setup.sh --help
```

**Command-line Options:**
- `-h, --help` - Show help message
- `-u, --user <username>` - Target user (default: current)
- `-t, --theme <theme>` - Oh My Zsh theme (default: duellj)
- `--skip-nvm` - Don't install NVM
- `--install-aws-cli` - Install AWS CLI v2
- `--minimal` - Skip fortune/cowsay/lolcat

**Features:**
- 10+ useful plugins pre-configured
- Professional aliases for git, docker, ansible, kubectl
- Useful functions (gcp, mkcd, extract, h)
- Auto-completion for kubectl, terraform, aws
- Enhanced history management
- Color-coded output and logging
- Automatic backup of existing .zshrc

**Prerequisites:**
- Root or sudo privileges
- Internet connectivity
- Ubuntu/Debian or RHEL-based system

---

### zabbixdeploy.sh (v2.0)
**Production-grade Zabbix agent installation script.**

**What it does:**
- ✅ **Checks if already installed (prevents duplicate installs)**
- ✅ Downloads and **verifies** Zabbix agent
- ✅ Creates system user with proper permissions
- ✅ Configures systemd service with security settings
- ✅ **Validates installation after completion**
- ✅ Automatic cleanup of temporary files
- ✅ Configurable via command-line options or environment variables
- ✅ Comprehensive error handling

**Usage:**
```bash
# Basic usage (uses defaults)
sudo ./zabbixdeploy.sh

# Custom Zabbix server
sudo ./zabbixdeploy.sh --server 192.168.1.50

# Specific version
sudo ./zabbixdeploy.sh --version 7.0.0

# Combined options
sudo ./zabbixdeploy.sh --server 192.168.1.50 --version 7.2.4

# Force reinstall
sudo ./zabbixdeploy.sh --reinstall

# Using environment variables
ZABBIX_SERVER=192.168.1.50 sudo ./zabbixdeploy.sh

# Show help
./zabbixdeploy.sh --help
```

**Command-line Options:**
- `-h, --help` - Show help message
- `-s, --server <IP>` - Zabbix server IP
- `-v, --version <VER>` - Zabbix version to install
- `-r, --reinstall` - Force reinstall

**Environment Variables:**
- `ZABBIX_SERVER` - Server IP (default: 100.85.45.123)
- `ZABBIX_VERSION` - Version (default: 7.2.4)
- `INSTALL_DIR` - Install path (default: /opt/zabbix)

**Features:**
- Download verification (checks file size)
- Configuration validation
- Service verification after start
- Automatic cleanup on exit (success or failure)
- Detailed status reporting
- Systemd service hardening (PrivateTmp, ProtectSystem, etc.)

**Prerequisites:**
- Root or sudo privileges
- `wget` or `curl` installed
- Systemd-based system
- Internet connectivity

---

---

## 🚀 Making Scripts Executable

```bash
cd scripts/
chmod +x setup-ssh-key-on-remote-host.sh
chmod +x deploy-zsh-setup.sh
chmod +x zabbixdeploy.sh
```

## ⚡ Quick Examples

### Setup SSH Key on Multiple Hosts
```bash
#!/bin/bash
# setup-multiple-hosts.sh
for host in 192.168.1.{100..110}; do
    ./setup-ssh-key-on-remote-host.sh "$host" ubuntu
done
```

### Deploy Zabbix to All Hosts (After SSH Setup)
```bash
# Use Ansible instead!
cd ../ansible/noble-semaphore
ansible-playbook deploy_zabbix_agent2.yaml
```

## 📊 Version 2.0 Improvements

### Both Scripts Now Have:

**Error Handling:**
- ✅ `set -euo pipefail` for strict error handling
- ✅ Trap handlers for cleanup
- ✅ Validation at every step
- ✅ Detailed error messages

**Safety Features:**
- ✅ Dependency checking
- ✅ Pre-flight validation
- ✅ Backup of configurations
- ✅ Verification before critical operations
- ✅ User confirmations

**User Experience:**
- ✅ Color-coded output (info/warn/error/success)
- ✅ Progress indicators
- ✅ Detailed help messages
- ✅ Completion summaries with next steps

**Configuration:**
- ✅ Command-line options
- ✅ Environment variable support
- ✅ Sensible defaults
- ✅ Easy to customize

**Production Ready:**
- ✅ Professional code structure
- ✅ Comprehensive logging
- ✅ Automatic cleanup
- ✅ Well documented

## 📝 Notes

- **For single-host deployments:** Use these scripts
- **For multi-host automation:** Use Ansible playbooks in `../ansible/noble-semaphore/`
- **SSH key location:** Scripts use `~/.ssh/ansible` by default
- **Zabbix version:** Update `ZABBIX_VERSION` as needed

## 🔗 Related Documentation

- [Ansible Playbooks](../ansible/noble-semaphore/ANSIBLE-README.md)
- [Semaphore Configuration](../ansible/noble-semaphore/configure-semaphore.py)

## 🆘 Troubleshooting

### setup-ssh-key-on-remote-host.sh

**Problem:** "Missing required dependencies: sshpass"
```bash
sudo apt install sshpass openssh-client
```

**Problem:** "SSH key authentication failed"
- Check if remote host allows SSH connections
- Verify user has sudo privileges
- Check if password is correct

### zabbixdeploy.sh

**Problem:** "Service is not running"
```bash
# Check logs
journalctl -u zabbix-agent -n 50
tail -f /var/log/zabbix/zabbix_agentd.log
```

**Problem:** "Download failed"
- Check internet connectivity
- Verify Zabbix version exists
- Try different version: `./zabbixdeploy.sh --version 7.0.0`

**Problem:** "Already installed"
- Use `--reinstall` flag: `sudo ./zabbixdeploy.sh --reinstall`