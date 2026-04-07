# Changelog

## [2026-04-08] - Fleet-Wide Unattended Upgrades + APT Repair

### Added
- **Fleet-Wide Unattended Upgrades (34 hosts)**
  - Deployed `unattended-upgrades` + `msmtp` to all 34 reachable Linux hosts via Ansible
  - All updates (security + regular) enabled on all Ubuntu 24.04 and Debian 13 hosts
  - Auto-reboot enabled: VMs at 05:30, Proxmox hypervisors at 06:30
  - Email alerts via Brevo SMTP to `unattended-upgrades@baggerzzz.online` on any change

- **Ansible Playbook: `configure-unattended-upgrades.yml`**
  - Idempotent playbook for full unattended-upgrades configuration
  - Automatically detects Proxmox vs VM hosts and applies correct schedule
  - Configures msmtp with `no_log: true` to prevent SMTP key leaking in logs
  - Tags: `install`, `msmtp`, `config`, `timer`, `verify`

- **Secret Management Pattern**
  - `group_vars/all/vars.yml` — non-secret config (schedule times, SMTP host, email)
  - `group_vars/all/vault.yml` — SMTP API key (chmod 600, gitignored)
  - `group_vars/all/vault.yml.example` — onboarding template
  - `.gitignore` added to noble-semaphore directory

- **APT Repair: pve-myst (100.119.135.11)**
  - Diagnosed dpkg SIGPIPE bug caused by 22.04→24.04 usrmerge `/lib` diversion
  - Manually extracted and installed 6 stuck packages (netplan, libfwupd2, lshw)
  - Updated dpkg status database via Python script
  - `libnetplan1` held with `apt-mark hold` pending upstream dpkg fix

- **motioneye (100.88.27.41)**
  - Fixed recurring 30s `apt-daily` timeout caused by `systemd-networkd-wait-online`
  - Added `APT::Periodic::WaitOnline "false"` to `/etc/apt/apt.conf.d/99nowaitonline`

### Changed
- **Update Schedule (all hosts)**
  - VMs: `apt-get update` at 04:00, upgrade at 05:00, reboot at 05:30
  - Proxmox (pve1/2/3): `apt-get update` at 05:00, upgrade at 06:00, reboot at 06:30
  - 1-hour gap ensures VMs complete reboot before hypervisors restart

### Files Added/Modified
- `ansible/noble-semaphore/configure-unattended-upgrades.yml` — new playbook
- `ansible/noble-semaphore/group_vars/all/vars.yml` — non-secret variables
- `ansible/noble-semaphore/group_vars/all/vault.yml.example` — secrets template
- `ansible/noble-semaphore/.gitignore` — excludes vault.yml from git
- `README.md` — updated with auto-update schedule, secret management docs

### Infrastructure State
- **Configured:** 34 hosts
- **Offline/skipped:** 1 host (100.96.238.4 — unreachable)
- **Held packages:** `libnetplan1` on pve-myst (safe, files at correct version)

---


## [2026-02-09] - Infrastructure Update & Reboot Strategy

### Added
- **Unattended-Upgrades Configuration**
  - Configured automatic updates and reboots for ansible control node
  - Set reboot time to 13:00 (1:00 PM) - 12 hours after scheduled playbook
  - Created comprehensive setup guide: `ansible/noble-semaphore/UNATTENDED-UPGRADES-GUIDE.md`

- **Safe Reboot Playbook**
  - Improved `playbook-update-reboot.yml` with proper ordering
  - VMs reboot first (in batches of 5)
  - Proxmox hosts reboot serially (one at a time)
  - Ansible control node explicitly excluded from playbook

- **Infrastructure Fixes**
  - Created symlink: `/opt/ansible/inventory` → `/opt/ansible/noble-semaphore/inventory`
  - Fixed Semaphore inventory path reference

### Changed
- **Update Schedule Coordination**
  - Friday 1:00 AM: Ansible playbook updates VMs and Proxmox hosts
  - Saturday 1:00 PM: Ansible control node reboots (if needed)
  - 12-hour gap prevents conflicts and ensures infrastructure stability

### Configuration Details

**Ansible Control Node (unattended-upgrades):**
- Automatic updates: Daily
- Automatic reboot: Enabled at 13:00 (1:00 PM)
- Reboot with users: Enabled
- Auto-clean: Weekly

**Ansible Playbook (`playbook-update-reboot.yml`):**
- Schedule: Fridays @ 1:00 AM
- VMs: Update and reboot in batches of 5
- Proxmox hosts: Update and reboot serially (one at a time)
- Ansible control node: Explicitly skipped

### Technical Notes

**Why This Approach:**
1. Ansible control node cannot safely reboot itself via playbook (would kill job)
2. Unattended-upgrades provides independent, reliable update mechanism
3. 12-hour gap ensures all infrastructure updates complete before control node reboots
4. Serial Proxmox reboots prevent complete infrastructure outage

**Safety Features:**
- Ansible control node protected from playbook reboots
- Proxmox hosts reboot one at a time (prevents HA cluster issues)
- VMs reboot before Proxmox hosts (proper dependency order)
- Staggered schedule prevents conflicts

### Files Modified
- `ansible/noble-semaphore/playbook-update-reboot.yml` - Added safe reboot ordering
- `ansible/noble-semaphore/UNATTENDED-UPGRADES-GUIDE.md` - Created comprehensive guide
- `/etc/apt/apt.conf.d/50unattended-upgrades` - Configured automatic reboots
- `/etc/apt/apt.conf.d/20auto-upgrades` - Enabled automatic updates
- `/opt/ansible/inventory` - Created symlink to correct location

### Testing Completed
- ✅ Service status verified (running and enabled)
- ✅ Upgrade logs functional
- ✅ Reboot-required detection working
- ✅ Playbook syntax validated
- ✅ Configuration tested with dry-run

### Monitoring Commands
```bash
# Check service status
sudo systemctl status unattended-upgrades

# View recent upgrade logs
sudo tail -50 /var/log/unattended-upgrades/unattended-upgrades.log

# Check if reboot required
ls /var/run/reboot-required && cat /var/run/reboot-required.pkgs

# View last reboots
last reboot

# Test dry-run
sudo unattended-upgrades --dry-run