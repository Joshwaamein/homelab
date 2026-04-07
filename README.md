# 🏠 Homelab Infrastructure Repository

This repository contains scripts, configurations, and automation tools for managing my homelab infrastructure.

## 📁 Repository Structure

```
homelab/
├── ansible/              # Ansible automation and playbooks
│   └── noble-semaphore/  # Production Ansible configuration
│       ├── group_vars/
│       │   └── all/
│       │       ├── vars.yml              # Non-secret variables
│       │       ├── vault.yml             # 🔒 Secrets (gitignored)
│       │       └── vault.yml.example     # Template for vault.yml
│       ├── configure-unattended-upgrades.yml  # Auto-updates & email alerts
│       ├── playbook-update-no-reboot.yml      # Manual system updates
│       ├── playbook-update-reboot.yml         # System updates with reboot
│       ├── secure_ssh_configuration.yml       # SSH hardening
│       ├── config-ufw.yml                     # Firewall rules
│       ├── setup.sh                           # One-click Ansible setup
│       └── configure-semaphore.py             # Semaphore auto-config
├── data-analytics/      # Multi-chain crypto & system and environment monitoring platform
│   ├── scripts/         # Data collection scripts (XRPL, Xahau, Ethereum, Prometheus)
│   ├── sql/             # PostgreSQL database schemas
│   ├── dashboards/      # Grafana dashboard templates
│   ├── utils/           # Shared utility functions
│   ├── setup.sh         # Automated database setup
│   └── README.md        # Platform documentation
├── scripts/             # Utility scripts organised by platform
│   ├── linux/           # Linux/Ubuntu scripts
│   │   ├── setup-ssh-key-on-remote-host.sh  # SSH key automation
│   │   ├── deploy-zsh-setup.sh              # Zsh environment setup
│   │   ├── zabbixdeploy.sh                  # Zabbix deployment
│   │   ├── unattended-upgrades.sh           # Automated Ubuntu updates
│   │   ├── ubuntu-apps.sh                   # Desktop app installer
│   │   └── fix-update-issues.sh             # Fix apt update issues
│   └── windows/         # Windows scripts
│       ├── Update-AllApps.ps1               # Update all Windows apps
│       └── zero_drive.py                    # Disk zeroing utility
├── semaphore/           # Semaphore UI configuration (not tracked)
└── README.md           # This file
```

## 🎯 Quick Start

### Ansible Automation
For detailed Ansible documentation, see [ansible/noble-semaphore/ANSIBLE-README.md](ansible/noble-semaphore/ANSIBLE-README.md)

**Quick setup:**
```bash
cd ansible/noble-semaphore
sudo ./setup.sh
```

## 🏗️ Infrastructure Components

### Data Analytics Platform
Multi-chain cryptocurrency and system monitoring platform with PostgreSQL backend.

**Features:**
- ✅ Multi-blockchain balance tracking (XRPL, Xahau, Ethereum)
- ✅ Raspberry Pi system metrics collection
- ✅ Evernode host statistics monitoring
- ✅ Automated database setup with SQL schemas
- ✅ Grafana dashboard templates included
- ✅ Centralized configuration management
- ✅ Production-ready with error handling and rate limiting

**Capabilities:**
- Track cryptocurrency balances with USD valuations
- Monitor Pi system metrics (CPU, memory, network)
- Collect internet speed test results
- Store Evernode host performance data
- Visualize data with pre-built Grafana dashboards

[→ Full Data Analytics Documentation](data-analytics/README.md)

### Ansible Automation
Complete infrastructure automation using Ansible with Semaphore UI.

**Features:**
- ✅ 10+ production-ready playbooks
- ✅ Automated system updates with email alerts
- ✅ **Unattended upgrades** — daily auto-updates + auto-reboot across 34 hosts
- ✅ Security hardening (SSH, UFW, Fail2ban)
- ✅ Monitoring (Zabbix agent deployment)
- ✅ Semaphore web UI integration
- ✅ Secrets managed via `group_vars/all/vault.yml` (gitignored)

**Key Playbooks:**
- `configure-unattended-upgrades.yml` — Daily auto-updates + Brevo email alerts (5 AM VMs / 6 AM Proxmox)
- `playbook-update-no-reboot.yml` — Manual updates without reboot
- `playbook-update-reboot.yml` — Manual updates with reboot
- `secure_ssh_configuration.yml` — SSH hardening
- `config-ufw.yml` — Firewall rules

[→ Full Ansible Documentation](ansible/noble-semaphore/ANSIBLE-README.md)

### Unattended Upgrades
Automated configuration of unattended upgrades for Ubuntu servers, ensuring systems receive regular security patches and package updates without manual intervention.

**Features:**
- ✅ Installs and configures unattended-upgrades package
- ✅ Automatic security and system package updates
- ✅ Scheduled automatic reboots at 1 AM if required
- ✅ Distribution upgrades and kernel updates excluded
- ✅ Unused dependencies automatically removed
- ✅ Daily cron job for upgrades

**Quick setup:**
```bash
curl -sSL https://raw.githubusercontent.com/Joshwaamein/homelab/main/scripts/linux/unattended-upgrades.sh | bash
```

[→ Full Scripts Documentation](scripts/linux/README.md)

### Ubuntu Apps
Automated installation script for setting up a fresh Ubuntu desktop with all essential applications and tools, using apt and dpkg where possible.

**Applications installed:**
- ✅ Visual Studio Code, Brave Browser, Discord
- ✅ VLC Media Player, Apache OpenOffice, Obsidian
- ✅ OneDrive, Tailscale, Private Internet Access
- ✅ Lutris, Steam
- ✅ Ubuntu Extensions
- ✅ Firmware and driver updates via fwupd and ubuntu-drivers

**Quick setup:**
```bash
curl -sSL https://raw.githubusercontent.com/Joshwaamein/homelab/main/scripts/linux/ubuntu-apps.sh | bash
```

[→ Full Scripts Documentation](scripts/linux/README.md)

### Semaphore
Web-based UI for Ansible automation with:
- Task scheduling
- Execution history
- Access control
- Secret management

## 🖥️ Infrastructure Overview

### Managed Systems
- **Ubuntu/Debian VMs** (31 hosts) — Various infrastructure services
- **Proxmox Hypervisors** (pve1, pve2, pve3) — Virtualization platform
- **Proxmox Backup Servers** (pbs1, pbs2, pbs3, pbs-t14) — Backup infrastructure
- **Evernode Instances** — XRPL nodes
- **Application Servers** — Servarrr, Pi-hole, UniFi, Bitwarden, Ghost, etc.

### Network
- **Tailscale VPN** — Secure remote access (100.x.x.x range)
- **Zabbix monitoring** — Infrastructure health monitoring
- **Brevo SMTP** — Email alerts from unattended-upgrades

### Auto-Update Schedule
| Time | Action | Hosts |
|------|--------|-------|
| 04:00 | `apt-get update` | All VMs |
| 05:00 | `apt-get upgrade` | All VMs |
| 05:30 | Auto-reboot if needed | All VMs |
| 05:00 | `apt-get update` | pve1, pve2, pve3 |
| 06:00 | `apt-get upgrade` | pve1, pve2, pve3 |
| 06:30 | Auto-reboot if needed | pve1, pve2, pve3 |

> Proxmox hypervisors update after VMs to ensure guests reboot before the host.

## 🔐 Security

### Protected Information
The following sensitive information is **excluded from git**:
- 🔒 Real server IPs and hostnames (inventory files)
- 🔒 Credentials and API keys (`group_vars/all/vault.yml`)
- 🔒 User data and reports
- 🔒 Semaphore runtime configuration

### Secret Management
Secrets are stored in `group_vars/all/vault.yml` (gitignored, chmod 600).
A `vault.yml.example` template is provided for onboarding.

To add a new secret:
1. Copy `vault.yml.example` → `vault.yml`
2. Add your values
3. Never commit vault.yml (it's in `.gitignore`)

### What's Safe to Share
- ✅ Playbook templates and scripts
- ✅ Configuration examples (`vault.yml.example`)
- ✅ Documentation
- ✅ Automation tools

## 📚 Documentation

### Component Documentation
- **[Data Analytics Platform](data-analytics/README.md)** - Crypto & system monitoring
- **[Ansible Automation](ansible/noble-semaphore/ANSIBLE-README.md)** - Complete Ansible guide
- **[Linux Scripts](scripts/linux/README.md)** - Linux/Ubuntu utility scripts
- **[Windows Scripts](scripts/windows/README.md)** - Windows utility scripts
- **[Setup Scripts](ansible/noble-semaphore/setup.sh)** - Installation automation
- **[Semaphore Config](ansible/noble-semaphore/configure-semaphore.py)** - Semaphore setup

### Key Features
- **Automated Daily Updates** — unattended-upgrades on all 34 hosts with email via Brevo
- **Security Hardening** — SSH, firewall, fail2ban
- **Monitoring** — Zabbix agent deployment
- **Backup Ready** — All configurations version controlled
- **Scheduled Tasks** — Automated maintenance via Semaphore

## 🚀 Getting Started

### Prerequisites
- Ubuntu/Debian system
- Python 3.x
- SSH access to managed hosts
- (Optional) Semaphore installed

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Joshwaamein/homelab.git
   cd homelab
   ```

2. **Set up Ansible:**
   ```bash
   cd ansible/noble-semaphore
   sudo ./setup.sh
   ```

3. **Configure inventory:**
   ```bash
   cp inventory.template inventory
   nano inventory  # Add your hosts
   ```

4. **Configure secrets:**
   ```bash
   cp group_vars/all/vault.yml.example group_vars/all/vault.yml
   nano group_vars/all/vault.yml  # Add SMTP key etc.
   chmod 600 group_vars/all/vault.yml
   ```

5. **(Optional) Configure Semaphore:**
   ```bash
   ./configure-semaphore.py
   ```

6. **Deploy unattended-upgrades to all hosts:**
   ```bash
   ansible-playbook configure-unattended-upgrades.yml
   ```

7. **Run a manual update:**
   ```bash
   ansible-playbook playbook-update-no-reboot.yml
   ```

## 🔧 Maintenance

### Regular Tasks (Automated via unattended-upgrades)
- **Daily 05:00** — System updates on all VMs (auto-reboot 05:30)
- **Daily 06:00** — System updates on Proxmox hosts (auto-reboot 06:30)
- **Email alerts** — Sent via Brevo on any package changes

### Manual Tasks
- Security configuration changes
- Firewall rule updates
- New service deployments
- Infrastructure expansion

## 📊 Monitoring

- **Zabbix Server:** Central monitoring
- **Agents:** Deployed on all managed systems
- **Alerting:** (Configure as needed)
- **Reporting:** Automated user audits

## 🤝 Contributing

This is a personal homelab repository, but feel free to:
- Use configurations as templates
- Suggest improvements
- Report issues

## 📝 Notes

### Structure Philosophy
- **Ansible** - Infrastructure as Code
- **Semaphore** - Web UI for operations
- **Git** - Version control for all configs
- **Security** - Secrets never committed

### Future Additions
This repository will grow to include:
- Container configurations
- Network diagrams
- Hardware documentation
- Service deployment guides
- Backup/restore procedures

## 🔗 Quick Links

- **[Ansible Documentation](ansible/noble-semaphore/ANSIBLE-README.md)** - Full Ansible guide
- **[Semaphore Setup](ansible/noble-semaphore/configure-semaphore.py)** - Auto-configure Semaphore
- **[Setup Script](ansible/noble-semaphore/setup.sh)** - Install all dependencies
- **[Linux Scripts](scripts/linux/README.md)** - Linux/Ubuntu utility scripts
- **[Windows Scripts](scripts/windows/README.md)** - Windows utility scripts

## 📜 License

Personal homelab configuration - Use at your own risk

---

**Repository:** https://github.com/Joshwaamein/homelab
**Purpose:** Infrastructure automation and documentation
**Status:** Active development


💡 **Tip:** Start with the [Ansible documentation](ansible/noble-semaphore/ANSIBLE-README.md) for detailed setup instructions.
