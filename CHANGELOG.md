# Changelog

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