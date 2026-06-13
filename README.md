# 🏠 Homelab Infrastructure Repository

Ansible playbooks, data-collection scripts, and utility tooling for
managing my homelab fleet. The fleet spans several sites stitched
together with a private overlay network; this repo is the
infrastructure-as-code that keeps it consistent.

> **Opsec:** real hostnames, IPs, ports, and secrets are kept out of
> this repo. Inventory and `vault.yml` are gitignored; published docs
> use `<placeholder>` names and omit port/IP detail. See
> [Security](#-security) below.

## 📁 Repository layout

```
.
├── ansible/noble-semaphore/   # Ansible control dir (playbooks, group_vars, templates)
│   ├── PLAYBOOKS.md           # ← canonical index of every playbook
│   ├── ANSIBLE-README.md      # setup + usage guide
│   ├── group_vars/            # per-group vars; vault.yml is gitignored
│   ├── templates/             # Jinja2 templates (zabbix agent conf, etc.)
│   ├── configfiles/           # static config snippets (fail2ban, sshd)
│   ├── zabbix-templates/      # importable Zabbix templates
│   ├── inventory.template     # inventory skeleton (real inventory gitignored)
│   ├── requirements.yml       # Ansible collection requirements
│   └── setup.sh               # one-shot control-node bootstrap
├── data-analytics/            # Crypto + system metrics collection platform
│   ├── scripts/               # XRPL/Xahau/ETH balance + Pi metrics collectors
│   ├── sql/                   # PostgreSQL schemas and views
│   ├── dashboards/            # Grafana dashboard JSON
│   └── utils/                 # shared helpers
├── scripts/
│   ├── linux/                 # Ubuntu/Debian setup, hardening, maintenance
│   ├── pbs/                   # Proxmox Backup Server helpers
│   └── windows/               # Windows utility scripts
├── CHANGELOG.md
└── README.md                  # this file
```

## 🎯 Quick start

```bash
git clone https://github.com/Joshwaamein/homelab.git
cd homelab/ansible/noble-semaphore

sudo ./setup.sh                       # install Ansible + collections
cp inventory.template inventory       # then edit with real hosts
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
chmod 600 group_vars/all/vault.yml    # add secrets, never commit this

ansible-playbook playbook-update-no-reboot.yml   # smoke test
```

Full setup and per-playbook usage live in the canonical sub-docs:

- **[ANSIBLE-README.md](ansible/noble-semaphore/ANSIBLE-README.md)** — control-node setup, inventory, vault.
- **[PLAYBOOKS.md](ansible/noble-semaphore/PLAYBOOKS.md)** — every playbook, its targets, and usage.

## 🤖 Ansible automation

22 playbooks, grouped the way `PLAYBOOKS.md` documents them:

| Area | Playbooks |
|------|-----------|
| **Security** | `config-f2b-protect-sshd.yaml` (fail2ban), `config-ufw.yml` (host firewall), `secure_ssh_configuration.yml`, `disable-ssh-password-auth.yml`, `security-audit-scan.yml`, `certificate-management-letsencrypt.yml` |
| **System maintenance** | `playbook-update-no-reboot.yml`, `playbook-update-reboot.yml`, `configure-unattended-upgrades.yml`, `configure-log-rotation.yml`, `set_timezone_noble_network.yml`, `fstrim-vm-storage-reclaim.yml`, `docker-health-and-cleanup.yml`, `update-pihole.yml`, `install-qemu-guest-agent.yml` |
| **Monitoring & management** | `deploy_zabbix_agent2.yaml`, `tailscale-net-zabbix-agent-playbook.yml`, `deploy-uu-zabbix-userparams.yml`, `enable-smart-monitoring-pbs.yml`, `verify-pbs-backups.yml`, `get-all-usernames.yml` |
| **Backup & config** | `backup-configs-to-git.yml` |

Secrets are referenced from `group_vars/all/vault.yml` (gitignored).
Per-group variables live in `group_vars/<group>.yml` (docker, grafana,
mysterium, pbs, pdm, proxmox, unifi_uos, unifi_legacy).

[→ Full playbook reference](ansible/noble-semaphore/PLAYBOOKS.md)

## 📊 Data analytics platform

PostgreSQL-backed collectors for multi-chain balances and system
metrics, with Grafana dashboards.

- **Collectors:** XRPL, Xahau, and Ethereum balance checks; Evernode
  host stats; Raspberry Pi metrics (CPU/memory/network, latency,
  speedtest, ISS pass tracking).
- **Storage:** SQL schemas and views under `data-analytics/sql/`.
- **Visualisation:** Grafana dashboard JSON under
  `data-analytics/dashboards/`.
- **Setup:** `data-analytics/setup.sh` provisions the database.

[→ Data analytics docs](data-analytics/README.md)

## 🔧 Utility scripts

| Platform | Highlights |
|----------|-----------|
| **Linux** (`scripts/linux/`) | SSH key deployment, Zsh setup, Zabbix agent install, unattended-upgrades, desktop app installer, apt repair, Cloudflare DDNS, update checks, reputation diagnostics |
| **PBS** (`scripts/pbs/`) | Proxmox Backup Server garbage-collection warning helper |
| **Windows** (`scripts/windows/`) | Bulk app updater, secure disk-zeroing utility |

[→ Linux scripts](scripts/linux/README.md) ·
[→ PBS scripts](scripts/pbs/README.md) ·
[→ Windows scripts](scripts/windows/README.md)

## 🔐 Security

Kept out of git (see `.gitignore`):

- Real inventory (hostnames, IPs) — only `inventory.template` is tracked.
- Credentials and API keys — `group_vars/all/vault.yml` (chmod 600);
  a `vault.yml.example` template is provided for onboarding.
- Runtime/operational data and reports.

Published docs deliberately redact hostnames (`<placeholder>` form),
ports, and IPs. Hardening covered by playbooks: host firewall (UFW),
fail2ban on SSH, SSH key-only auth, and a security-audit scan.

## 🤝 Contributing

Personal homelab repo. Configurations are reusable as templates; issues
and suggestions welcome. Treat everything as "use at your own risk".

## 📜 License

Personal homelab configuration. Use at your own risk.

---

**Repository:** https://github.com/Joshwaamein/homelab ·
**Start here:** [ANSIBLE-README.md](ansible/noble-semaphore/ANSIBLE-README.md)
and [PLAYBOOKS.md](ansible/noble-semaphore/PLAYBOOKS.md)
