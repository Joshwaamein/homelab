# Changelog

## [2026-05-27] - SMART Monitoring Enabled on PBS Hosts

### Added
- **`enable-smart-monitoring-pbs.yml`** — Idempotent playbook that installs
  `sudo` and `smartmontools` on the 3 PBS hosts and drops in
  `/etc/sudoers.d/zabbix-smartctl` granting the `zabbix` user `NOPASSWD`
  access to `/usr/sbin/smartctl` (the same policy already in place on
  pve1/pve2/pve3). Validates the sudoers file with `visudo -cf`, restarts
  `zabbix-agent2`, and confirms the SMART plugin's exact call path
  (`sudo -u zabbix sudo -n smartctl --scan -j`) returns `exit_status: 0`.

### Fixed
- The `SMART by Zabbix agent 2` template was already attached to pbs1/2/3
  but failing every LLD pass with
  `failed to scan for devices: ... exec: "sudo": executable file not found
  in $PATH`. PBS ships lean (no `sudo` package), so the agent's plugin
  could not elevate to call `smartctl`. After the playbook, the LLD on all
  3 PBS hosts cleared (`state=0`, no error) and disks started populating
  in Zabbix (pbs1: 3 disks, pbs2: 2 disks, pbs3: 3 disks including the
  USB-bridged ST1000LM024 / `/dev/sdc` that backs the `usb-backup`
  datastore).
- Bumped `Plugins.Smart.Timeout=10` (from default 3 s) on `pbs3` and
  `pve3` because both have USB-bridged drives whose first attribute read
  occasionally took > 0.5 s and produced a `Timeout occurred while
  gathering data.` LLD error during agent restart cycles.

### Verified
- `pve1/2/3` SMART monitoring still healthy: 45/72/21 items, 48/72/24
  triggers (pre-existing).
- `pbs3` post-fix: items=14 and growing, triggers=12,
  `[sdc sat]: Reallocated_Sector_Ct=0`, `Power_On_Hours=8578`,
  `Device model=ST1000LM024 HN-M101MBB` visible.
- All 6 hosts (pve1/2/3 + pbs1/2/3) now have `state=0` on the
  `smart.disk.discovery` LLD.

### Vikunja
- Closes task **#34** ("Get Zabbix to monitor SMART on PVE hosts").
- Extends task **#301** (pbs3 disk health) by giving its
  `UDMA_CRC_Error_Count`, `Reallocated_Sector_Ct`, and
  `Current_Pending_Sector` attributes a Zabbix item path so future
  changes alert via the bundled `Some prefail Attributes <= threshold`
  trigger prototype.

---

## [2026-05-25] - PBS Hosts Joined Unattended-Upgrades

### Added
- **`group_vars/pbs.yml`** — `ansible_become: false` for the `[pbs]` inventory group.
  - Proxmox Backup Server hosts run Debian 13 (trixie) without `sudo` installed.
  - Ansible already authenticates as `root` over SSH on these hosts, so privilege
    escalation is unnecessary and was the failure mode.

### Fixed
- `configure-unattended-upgrades.yml` previously failed on the 3 PBS hosts with
  `module_stderr: /bin/sh: 1: sudo: not found` (rc=127). With the new group_var
  the playbook is fully idempotent across the PBS group.

### Verified
- `ansible-playbook -i inventory configure-unattended-upgrades.yml --limit pbs`
  returns `ok=16 changed=0` across all 3 reachable PBS hosts.
- Fleet audit (`ansible all -m shell -a "..."`) confirms 27/27 reachable
  Debian/Ubuntu hosts have an active `apt-daily-upgrade.timer` and the
  configured 50unattended-upgrades file present.

### Out of Scope (deferred)
- 3 hosts unreachable on Tailscale (one Proxmox node, one Ubuntu test VM, one
  PBS laptop). UU coverage will pick up automatically on next playbook run
  once SSH is restored. Tracked in Vikunja `homelab-pointers` task list.

---

## [2026-04-08] - Fleet-Wide Unattended Upgrades + APT Repair

### Added
- **Fleet-Wide Unattended Upgrades (34 hosts)**
  - Deployed `unattended-upgrades` + `msmtp` to all 34 reachable Linux hosts via Ansible
  - All updates (security + regular) enabled on all Ubuntu 24.04 and Debian 13 hosts
  - Auto-reboot enabled: VMs at 05:30, Proxmox hypervisors at 06:30
  - Email alerts via Brevo SMTP to `unattended-upgrades@example.org` on any change

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

- **APT Repair: VM (`<vm-host>`, 100.x.x.x)**
  - Diagnosed dpkg SIGPIPE bug caused by 22.04→24.04 usrmerge `/lib` diversion
  - Manually extracted and installed 6 stuck packages (netplan, libfwupd2, lshw)
  - Updated dpkg status database via Python script
  - `libnetplan1` held with `apt-mark hold` pending upstream dpkg fix

- **Camera VM (`<vm-host>`, 100.x.x.x)**
  - Fixed recurring 30s `apt-daily` timeout caused by `systemd-networkd-wait-online`
  - Added `APT::Periodic::WaitOnline "false"` to `/etc/apt/apt.conf.d/99nowaitonline`

### Changed
- **Update Schedule (all hosts)**
  - VMs: `apt-get update` at 04:00, upgrade at 05:00, reboot at 05:30
  - Proxmox hypervisors: `apt-get update` at 05:00, upgrade at 06:00, reboot at 06:30
  - 1-hour gap ensures VMs complete reboot before hypervisors restart

### Files Added/Modified
- `ansible/noble-semaphore/configure-unattended-upgrades.yml` — new playbook
- `ansible/noble-semaphore/group_vars/all/vars.yml` — non-secret variables
- `ansible/noble-semaphore/group_vars/all/vault.yml.example` — secrets template
- `ansible/noble-semaphore/.gitignore` — excludes vault.yml from git
- `README.md` — updated with auto-update schedule, secret management docs

### Infrastructure State
- **Configured:** 34 hosts
- **Offline/skipped:** 1 host (100.x.x.x, unreachable)
- **Held packages:** `libnetplan1` on the affected VM (safe, files at correct version)

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