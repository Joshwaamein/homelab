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

### cloudflare_ddns.sh

**Cloudflare DDNS updater for a single A record.**

Reads credentials and target zone from `/etc/ddns/cloudflare.env`
(chmod 600, root:root). Updates only when the public IP differs from
the existing record. Designed to run from cron every 15 minutes.

- Idempotent (no API call if IP unchanged)
- Exits non-zero on any API failure so cron mail surfaces it
- Token, zone ID, and record name all injected via env file, nothing
  baked into the script

```bash
# 1. create the env file (root-only, never commit)
sudo install -d -m 700 /etc/ddns
sudo cp cloudflare.env.example /etc/ddns/cloudflare.env
sudo chmod 600 /etc/ddns/cloudflare.env
sudoedit /etc/ddns/cloudflare.env   # fill in API_TOKEN, ZONE_ID, RECORD_NAME

# 2. install
sudo install -m 755 cloudflare_ddns.sh /usr/local/sbin/cloudflare_ddns.sh

# 3. cron every 15 minutes
echo '*/15 * * * * root /usr/local/sbin/cloudflare_ddns.sh >> /var/log/cloudflare_ddns.log 2>&1' | sudo tee /etc/cron.d/cloudflare-ddns
```

The Cloudflare API token only needs `Zone : DNS : Edit` scoped to the
specific zone. Don't grant Account-level permissions.

**Companion file:** `cloudflare.env.example` (template for the env
file the DDNS script reads, never commit the populated version).

---

### check_updates.sh

**Tiny helper for Zabbix monitoring: counts available apt updates.**

Six lines. Drop on a host as a Zabbix UserParameter or external check.

```bash
echo 'UserParameter=apt.updates.count,/usr/local/bin/check_updates.sh' | \
  sudo tee /etc/zabbix/zabbix_agent2.d/apt-updates.conf
sudo systemctl restart zabbix-agent2
```

Then create an item `apt.updates.count` in your template, integer
type, poll daily.

---

### diagnose_bad_rep.sh

**Quick diagnostics dump for a misbehaving Sashimono reputation
daemon (Evernode hosts).**

Reads service status, recent ReputationD logs, lease offers,
resource usage, and Evernode host status into a single output for
post-mortem.

```bash
sudo bash diagnose_bad_rep.sh | tee /tmp/bad-rep-diagnostics.txt
```

The "replace `<user>` and `<name>`" comments in the contract-log
sections are deliberate placeholders. Edit them in if you want
contract-side log dumps too.

---

## 🚀 Making Scripts Executable

```bash
cd scripts/linux/
chmod +x *.sh
```
