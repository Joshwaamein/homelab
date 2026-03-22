# 🔧 Utility Scripts

This directory contains utility scripts for homelab management and setup, organised by platform.

## 📁 Structure

```
scripts/
├── linux/                              # Linux/Ubuntu scripts
│   ├── setup-ssh-key-on-remote-host.sh # SSH key deployment
│   ├── deploy-zsh-setup.sh             # Zsh environment setup
│   ├── zabbixdeploy.sh                 # Zabbix agent installer
│   ├── unattended-upgrades.sh          # Automated Ubuntu updates
│   ├── ubuntu-apps.sh                  # Desktop app installer
│   ├── fix-update-issues.sh            # Fix apt update issues
│   └── README.md                       # Linux scripts documentation
└── windows/                            # Windows scripts
    ├── Update-AllApps.ps1              # Update all Windows apps
    ├── zero_drive.py                   # Disk zeroing utility
    └── README.md                       # Windows scripts documentation
```

## 🐧 Linux Scripts

Scripts for Ubuntu/Debian server and desktop setup, security hardening, and maintenance.

[→ Full Linux Scripts Documentation](linux/README.md)

| Script | Description |
|--------|-------------|
| `setup-ssh-key-on-remote-host.sh` | SSH key deployment with safety checks |
| `deploy-zsh-setup.sh` | Complete zsh environment setup |
| `zabbixdeploy.sh` | Production-grade Zabbix agent installer |
| `unattended-upgrades.sh` | Automated Ubuntu security updates |
| `ubuntu-apps.sh` | Ubuntu desktop application installer |
| `fix-update-issues.sh` | Fix common apt update issues |

## 🪟 Windows Scripts

Scripts for Windows system management and utilities.

[→ Full Windows Scripts Documentation](windows/README.md)

| Script | Description |
|--------|-------------|
| `Update-AllApps.ps1` | Update all installed Windows applications |
| `zero_drive.py` | Securely zero a disk with progress reporting |

## 📝 Notes

- **Linux scripts:** Run with `chmod +x` first, most require `sudo`
- **Windows scripts:** Run from an elevated (Administrator) terminal
- **For multi-host automation:** Use Ansible playbooks in `../ansible/noble-semaphore/`
