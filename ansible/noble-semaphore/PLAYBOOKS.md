# Noble Network Ansible Playbooks Documentation

Complete guide to all Ansible playbooks for managing the Noble Network infrastructure.

## Table of Contents

1. [Security Playbooks](#security-playbooks)
2. [System Maintenance](#system-maintenance)
3. [Monitoring & Management](#monitoring--management)
4. [Service Configuration](#service-configuration)
5. [Quick Reference](#quick-reference)

---

## Security Playbooks

### 1. fail2ban Protection (`config-f2b-protect-sshd.yaml`)

**Purpose:** Protects SSH access with automated IP banning

**Targets:** `ubuntu_vms`, `pbs`, `hosts`

**Configuration:**
- Ban time: 1 hour
- Max retries: 5 attempts
- Find time: 10 minutes

**Usage:**
```bash
ansible-playbook config-f2b-protect-sshd.yaml
```

**Exclusions:**
- motioneye - LXC container with Debian 13 compatibility issues

**Notes:** Works on both Debian (apt) and RedHat (dnf) systems

---

### 2. UFW Firewall (`config-ufw.yml`)

**Purpose:** Configures host-based firewall rules for all services

**Targets:** `ubuntu_vms`, `noble_net_alma`, `evernode`, `xahau`, `unifi`, `nginx`, `servarr`, `pi4`, `pve_data`, `presearch`, `myst`, `ubuntu_docker`, `discord_bot`, `pihole`, `motioneye`, `ansible`, `hosts`

**Features:**
- Automatic service detection based on inventory groups
- SSH protection with rate limiting
- Application-specific rules
- Emergency rescue block (disables UFW on failure)

**Usage:**
```bash
ansible-playbook config-ufw.yml
```

**Firewall Rules by Group:**
- **Base (all hosts):** SSH (22), Zabbix (10050), Tailscale (41641)
- **Evernode:** HTTP/HTTPS, XRPL ports, Contract ports (36525-36531, 39064-39070, 22861-22864)
- **UniFi:** Controller ports (8080, 8443, 8843, 8880, 6789, 3478, 10001, 1900)
- **Nginx:** HTTP (80), HTTPS (443)
- **Pi-hole:** DNS (53), DHCP (67, 547), Web UI (80, 443)
- **Servarr:** All *arr apps, Jellyfin, Portainer, TVHeadend
- **Docker hosts:** Portainer, Vikunja (3456), Beaverhabits (8081)
- **Mysterium:** API (4449), Transactor (44158), P2P (45969)
- **MotionEye:** Web (8765), Streaming (8081)

**Safety:** Automatically skips Proxmox hypervisors and PBS servers

---

### 3. SSH Hardening (`secure_ssh_configuration.yml`)

**Purpose:** Hardens SSH configuration across all Linux hosts

**Targets:** `ubuntu_vms`, `pbs`, `hosts`, `noble_net_alma`

**Security Settings:**
- Root login: Key-based only (`prohibit-password`)
- Password authentication: Disabled
- Empty passwords: Disabled
- Pubkey authentication: Enabled
- X11 forwarding: Disabled
- Client alive interval: 300 seconds
- Client alive count max: 2

**Usage:**
```bash
ansible-playbook secure_ssh_configuration.yml
```

**Safety Features:**
- Verifies SSH keys exist before disabling passwords
- Backs up sshd_config before changes
- Validates syntax before applying
- Comprehensive configuration summary

**Warning:** This disables password login. Ensure SSH keys are working first!

---

### 4. Security Audit (`security-audit-scan.yml`)

**Purpose:** Comprehensive security scanning and vulnerability detection

**Targets:** `ubuntu_vms`, `noble_net_alma`, `pbs`, `hosts`

**Scans Performed:**
- Rootkit detection (rkhunter, chkrootkit)
- Security auditing (Lynis)
- CVE vulnerability scanning (debsecan)
- fail2ban status and banned IPs
- Failed SSH login attempts
- Suspicious sudo activity
- World-writable files in /etc
- Listening ports

**Usage:**
```bash
ansible-playbook security-audit-scan.yml
```

**Tools Installed:**
- rkhunter
- chkrootkit
- lynis (Debian/Ubuntu)
- debsecan (Debian/Ubuntu)

**Frequency:** Run weekly or after major changes

---

## System Maintenance

### 5. QEMU Guest Agent (`install-qemu-guest-agent.yml`)

**Purpose:** Installs QEMU Guest Agent for better Proxmox VM integration

**Targets:** `ubuntu_vms`, `pbs`

**Benefits:**
- Better VM management
- Coordinated shutdowns
- IP address reporting to Proxmox
- Enhanced monitoring

**Usage:**
```bash
ansible-playbook install-qemu-guest-agent.yml
```

**Exclusions:**
- motioneye - LXC container

**Requirements:** VM must have QEMU Guest Agent enabled in Proxmox settings

---

### 6. System Updates (`playbook-update-reboot.yml` / `playbook-update-no-reboot.yml`)

**Purpose:** Update all packages on Linux systems

**Targets:** Various

**Usage:**
```bash
# With reboot
ansible-playbook playbook-update-reboot.yml

# Without reboot
ansible-playbook playbook-update-no-reboot.yml
```

---

### 7. Timezone Configuration (`set_timezone_noble_network.yml`)

**Purpose:** Sets timezone to Europe/London across all systems

**Targets:** `ubuntu_vms`, `noble_net_alma`, `hosts`, `pbs`

**Usage:**
```bash
ansible-playbook set_timezone_noble_network.yml
```

**Features:**
- Verifies timezone was set correctly
- Restarts cron services appropriately
- Comprehensive reporting
- Only runs on systemd systems

---

### 8. fstrim Storage Reclamation (`fstrim-vm-storage-reclaim.yml`) ⭐ NEW

**Purpose:** Reclaims unused space on thin-provisioned VM disks

**Targets:** `ubuntu_vms`, `noble_net_alma`

**Benefits:**
- Can save 10-50% disk space
- Works with thin-provisioned storage
- Requires QEMU Guest Agent

**Usage:**
```bash
ansible-playbook fstrim-vm-storage-reclaim.yml
```

**Features:**
- Shows before/after disk usage
- Reports bytes trimmed per filesystem
- Enables weekly fstrim.timer
- Installs util-linux if missing

**Frequency:** Run weekly or after large file deletions

---

### 9. Log Rotation (`configure-log-rotation.yml`) ⭐ NEW

**Purpose:** Prevents disk fills by rotating and compressing logs

**Targets:** `ubuntu_vms`, `noble_net_alma`, `pbs`, `hosts`

**Configurations:**
- **System logs:** Daily rotation, 7 days retention, compressed
- **Docker logs:** 10MB max per container, 3 files retained
- **Zabbix logs:** Weekly rotation, 12 weeks retention, 100MB max
- **APT logs:** Weekly rotation, 4 weeks retention

**Usage:**
```bash
ansible-playbook configure-log-rotation.yml
```

**Features:**
- Auto-detects services (Docker, Zabbix)
- Shows top 10 largest logs
- Tests configuration before applying
- Can force immediate rotation

---

### 10. Docker Health & Cleanup (`docker-health-and-cleanup.yml`) ⭐ NEW

**Purpose:** Maintains Docker hosts by cleaning unused resources

**Targets:** `ubuntu_vms` (auto-detects Docker hosts)

**Cleanup Actions:**
- Removes stopped containers
- Removes unused images
- Removes unused volumes
- Removes unused networks
- Clears build cache

**Usage:**
```bash
ansible-playbook docker-health-and-cleanup.yml
```

**Features:**
- Shows before/after disk usage
- Lists all containers and their status
- Identifies unhealthy containers
- Comprehensive reporting of reclaimed space

**Safety:** Only prunes truly unused resources, running containers are untouched

**Frequency:** Run monthly or when disk space is low

---

## Monitoring & Management

### 11. Zabbix Agent Deployment (`tailscale-net-zabbix-agent-playbook.yml`) ⭐ ENHANCED

**Purpose:** Intelligent Zabbix Agent 2 deployment with auto-configuration

**Targets:** `ubuntu_vms`, `pbs`, `hosts`

**Features:**
- Installs/upgrades to Zabbix Agent 2
- Auto-detects Tailscale IPs
- Dynamic template assignment based on inventory groups
- Dynamic host group assignment
- Automatic tagging (Environment, Location, OS, Role, Hardware)
- Creates Zabbix host groups automatically
- Updates existing hosts or creates new ones
- Enables safe discovery

**Usage:**
```bash
ansible-playbook tailscale-net-zabbix-agent-playbook.yml
```

**Requirements:**
- Zabbix credentials in vault.yml:
  - `zabbix_admin_user`
  - `zabbix_admin_password`

**Template Mapping:**
- **Evernode:** "Linux by Zabbix agent active", "Docker by Zabbix agent active"
- **Nginx:** "Linux by Zabbix agent active", "Nginx by Zabbix agent"
- **Servarr:** "Linux by Zabbix agent active", "Docker by Zabbix agent active"

**Note:** Manually import custom templates in Zabbix UI, then update playbook variables

---

### 12. Zabbix Agent (Legacy) (`deploy_zabbix_agent2.yaml`)

**Purpose:** Basic Zabbix Agent 2 installation (superseded by tailscale version)

**Status:** ⚠️ **Deprecated** - Use `tailscale-net-zabbix-agent-playbook.yml` instead

---

## Service Configuration

### 13. Certificate Management (`certificate-management-letsencrypt.yml`) ⭐ NEW

**Purpose:** Automates Let's Encrypt SSL certificate management

**Targets:** `nginx`, `pihole`, `pve_data`

**Features:**
- Installs certbot and nginx plugin
- Lists existing certificates
- Checks expiration dates
- Sets up automatic renewal (daily at 3 AM)
- Tests renewal process (dry run)

**Usage:**
```bash
ansible-playbook certificate-management-letsencrypt.yml
```

**To Request New Certificate:**
```bash
ssh root@nginx-host
certbot --nginx -d yourdomain.com
```

**Requirements:**
- Domain DNS must point to the server
- Port 80 must be accessible for validation
- Set `vault_letsencrypt_email` in vault.yml (optional)

---

### 14. Configuration Backup (`backup-configs-to-git.yml`) ⭐ NEW

**Purpose:** Backs up critical configuration files from all hosts

**Targets:** `ubuntu_vms`, `noble_net_alma`, `pbs`, `hosts`

**Backed Up Configs:**
- SSH configuration (sshd_config)
- fail2ban configuration
- UFW firewall rules
- Cron jobs
- Network configuration (netplan)
- Docker compose files
- Nginx configuration
- Zabbix agent configuration

**Usage:**
```bash
ansible-playbook backup-configs-to-git.yml
```

**Backup Location:** `/root/config-backups/{hostname}/`

**Features:**
- Timestamped backups
- Comprehensive manifest file
- Shows total backup size
- Lists all backed up files

**Next Steps:**
1. Pull backups to central location
2. Commit to git repository
3. Set up automated sync

---

### 15. PBS Backup Verification (`verify-pbs-backups.yml`) ⭐ NEW

**Purpose:** Verifies Proxmox Backup Server health and backup status

**Targets:** `pbs`

**Checks Performed:**
- PBS service status
- Datastore list and status
- Recent backups (< 48 hours)
- Old backups (> 30 days)
- Total backup count
- Datastore disk usage
- Failed backup tasks
- Garbage collection status

**Usage:**
```bash
ansible-playbook verify-pbs-backups.yml
```

**Recommendations Generated:**
- ✓ Backups are current / ⚠ No recent backups
- ✓ Retention healthy / ⚠ Consider pruning old backups

**Frequency:** Run daily or weekly

---

## Quick Reference

### Playbook Execution Order (First-Time Setup)

1. **Timezone** → Set correct timezone
2. **SSH Hardening** → Secure SSH access
3. **fail2ban** → Protect SSH from brute force
4. **UFW** → Configure firewall rules
5. **QEMU Guest Agent** → Enable VM features
6. **Zabbix Agent** → Enable monitoring
7. **Log Rotation** → Prevent disk fills
8. **Security Audit** → Verify security posture

### Maintenance Schedule

**Daily:**
- Certificate renewal (automatic via cron)

**Weekly:**
- fstrim (automatic via timer)
- Security audit
- PBS backup verification

**Monthly:**
- Docker cleanup
- Configuration backup
- Review security audit reports

**As Needed:**
- System updates
- UFW rule changes
- Zabbix host configuration updates

---

## Common Variables (group_vars/all/vars.yml)

```yaml
# Zabbix Configuration
zabbix_server_ip: "<your_zabbix_server_ip>"
zabbix_version: "7.0"

# Timezone Configuration  
timezone: "Europe/London"

# SSH Configuration
ssh_permit_root_login: "prohibit-password"
ssh_password_authentication: false
ssh_permit_empty_passwords: false
ssh_x11_forwarding: false
ssh_client_alive_interval: 300
ssh_client_alive_count_max: 2

# System Updates
update_cache_valid_time: 3600
```

---

## Sensitive Variables (group_vars/all/vault.yml)

```yaml
# Zabbix Credentials
zabbix_admin_user: "<your_admin_user>"
zabbix_admin_password: "<your_secure_password>"

# Let's Encrypt Email (optional)
vault_letsencrypt_email: "<your_email@example.com>"
```

**Security:** Encrypt this file with `ansible-vault encrypt group_vars/all/vault.yml`

---

## Inventory Groups

### Infrastructure Groups
- `[ubuntu_vms]` - All Ubuntu/Debian VMs
- `[noble_net_alma]` - AlmaLinux VMs
- `[hosts]` - Proxmox hypervisors + Raspberry Pis
- `[pbs]` - Proxmox Backup Servers
- `[proxmox]` - Proxmox hypervisors only

### Application Groups
- `[evernode]` - Evernode blockchain hosts
- `[xahau]` - Xahau blockchain host
- `[unifi]` - UniFi Controllers
- `[nginx]` - Nginx web servers
- `[pihole]` - Pi-hole DNS servers
- `[servarr]` / `[servarrr]` - Media stack
- `[ubuntu_docker]` - Docker hosts
- `[motioneye]` - MotionEye surveillance
- `[discord_bot]` - Discord bot hosts
- `[pve_data]` - Data services (Grafana, InfluxDB, PostgreSQL)
- `[presearch]` - Presearch nodes
- `[myst]` - Mysterium DVPN nodes
- `[pi4]` - Raspberry Pi 4 devices
- `[ansible]` - Ansible/Semaphore management host

---

## Troubleshooting

### Common Issues

**1. Host Unreachable**
- Solution: `ignore_unreachable: true` is set on all playbooks
- Check Tailscale connectivity: `tailscale ping <host_ip>`

**2. SSH Key Authentication Fails**
- Ensure keys are in `/root/.ssh/authorized_keys`
- Test manually: `ssh root@<host_ip>`

**3. Zabbix Host Not Created**
- Verify credentials in vault.yml
- Check Zabbix server is accessible: `curl http://<zabbix_server_ip>`
- Manually create host groups in Zabbix UI

**4. UFW Locks Out SSH**
- Won't happen - playbook ensures SSH is allowed FIRST
- Rescue block disables UFW on any error

**5. fail2ban Service Not Found (motioneye)**
- Expected - LXC container on Debian 13 Trixie
- Host is excluded from playbook

**6. QEMU Guest Agent Fails**
- Check VM has Guest Agent enabled in Proxmox
- For LXC containers, exclude from playbook

---

## Advanced Usage

### Run Specific Tags

```bash
# Only install fail2ban, don't configure
ansible-playbook config-f2b-protect-sshd.yaml --tags install

# Only run security scans, skip installs
ansible-playbook security-audit-scan.yml --tags audit

# Only configure Zabbix agent, skip installation
ansible-playbook tailscale-net-zabbix-agent-playbook.yml --tags agent
```

### Limit to Specific Hosts

```bash
# Single host
ansible-playbook config-ufw.yml --limit <host_ip>

# Group
ansible-playbook secure_ssh_configuration.yml --limit evernode

# Multiple hosts
ansible-playbook fstrim-vm-storage-reclaim.yml --limit 'evernode,nginx'
```

### Dry Run (Check Mode)

```bash
ansible-playbook secure_ssh_configuration.yml --check
```

**Note:** Some playbooks don't work well in check mode (handlers, command modules)

---

## Best Practices

### Before Running Any Playbook

1. **Test on one host first:** Use `--limit` flag
2. **Review the playbook:** Understand what it does
3. **Check variables:** Ensure vars.yml and vault.yml are correct
4. **Backup important data:** Especially for destructive operations
5. **Have console access:** In case SSH is affected

### After Running Playbooks

1. **Review output:** Check for errors or warnings
2. **Verify services:** Test that applications still work
3. **Check logs:** Review /var/log for issues
4. **Run verification:** Use security-audit or service-specific checks
5. **Document changes:** Update your runbook

### Security Considerations

1. **Keep vault.yml encrypted:** Use ansible-vault
2. **Rotate credentials regularly:** Especially Zabbix passwords
3. **Review fail2ban bans:** Check for attack patterns
4. **Monitor certificate expiration:** Let's Encrypt is automatic but verify
5. **Regular security audits:** Run monthly minimum

---

## Files Modified During This Enhancement Session

### Fixed/Enhanced:
- `config-f2b-protect-sshd.yaml` - Added motioneye exclusion
- `config-ufw.yml` - Fixed port ranges, added ports, comprehensive audit
- `install-qemu-guest-agent.yml` - Added motioneye exclusion
- `secure_ssh_configuration.yml` - Added 6 security settings, fixed 4 bugs
- `set_timezone_noble_network.yml` - Added reporting and verification
- `inventory` - Added motioneye, uncommented triton-pi, added pve3, commented separator
- `group_vars/all/vars.yml` - Added SSH security variables

### Created:
- `tailscale-net-zabbix-agent-playbook.yml` - Intelligent merged Zabbix deployment
- `fstrim-vm-storage-reclaim.yml` - Storage reclamation
- `configure-log-rotation.yml` - Log management
- `docker-health-and-cleanup.yml` - Docker maintenance
- `certificate-management-letsencrypt.yml` - SSL automation
- `security-audit-scan.yml` - Vulnerability scanning
- `backup-configs-to-git.yml` - Configuration backup
- `verify-pbs-backups.yml` - Backup verification

---

## Critical Bugs Fixed

1. **UFW Evernode Port Ranges** - Port range syntax incompatibility (36525-36531, etc.)
2. **Inventory Separator** - Line treated as hostname causing unreachable errors
3. **SSH Windows Detection** - Incorrect ansible_facts dict access
4. **SSH Handler async** - Conflict with check mode
5. **SSH wait_for IPs** - Checking LAN IPs instead of Tailscale IPs
6. **Zabbix Discovery Security** - Removed dangerous system.run AllowKey

---

## Support & Maintenance

**Author:** Enhanced during comprehensive playbook review session  
**Date:** February 2026  
**Version:** 2.0

**For Issues:**
- Review playbook output carefully
- Check `/var/log` on affected hosts
- Verify inventory groups are correct
- Ensure required variables are defined

**Future Enhancements:**
- Add custom Zabbix templates
- Implement backup verification with test restores
- Add alerting integration (Slack/Discord)
- Implement automated rollback on failures
