# Unattended-Upgrades Configuration for Ansible Control Node

## Overview

This guide explains how to configure automatic updates and reboots on the ansible/semaphore control node using `unattended-upgrades`. This approach is necessary because the ansible control node cannot safely reboot itself through ansible playbooks.

## Why This Approach?

**Problem:** If ansible tried to reboot itself via playbook:
- The playbook execution would be killed mid-run
- No confirmation of successful reboot
- Potential for incomplete updates

**Solution:** Use Ubuntu's built-in `unattended-upgrades` to handle automatic updates and reboots independently of ansible.

## Installation

```bash
# Install unattended-upgrades package
sudo apt update
sudo apt install unattended-upgrades apt-listchanges -y
```

## Configuration

### Step 1: Enable Automatic Updates

Edit `/etc/apt/apt.conf.d/50unattended-upgrades`:

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Key settings to configure:

```conf
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "${distro_id}:${distro_codename}-updates";
};

// Automatically reboot if required (CRITICAL for kernel updates)
Unattended-Upgrade::Automatic-Reboot "true";

// Reboot at 1:00 PM (13:00) - 12 hours after ansible playbook runs
Unattended-Upgrade::Automatic-Reboot-Time "13:00";

// Reboot even if users are logged in
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";

// Remove unused kernel packages and dependencies
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Email notifications (optional - requires mail setup)
// Unattended-Upgrade::Mail "root";
// Unattended-Upgrade::MailReport "only-on-error";
```

### Step 2: Enable Automatic Updates Service

Edit `/etc/apt/apt.conf.d/20auto-upgrades`:

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

Content:

```conf
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

### Step 3: Enable and Start Service

```bash
# Enable the service
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades

# Check status
sudo systemctl status unattended-upgrades
```

## Verification

### Check Configuration

```bash
# Test the configuration (dry run)
sudo unattended-upgrades --dry-run --debug

# Check current status
sudo systemctl status unattended-upgrades

# View logs
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log
```

### Check Reboot Status

```bash
# Check if reboot is required
ls /var/run/reboot-required

# View reason for reboot
cat /var/run/reboot-required.pkgs
```

## Update Schedule

- **Daily:** Automatic check for updates
- **Daily:** Download and install security updates
- **As Needed:** Automatic reboot at 1:00 PM (13:00) if kernel/system updates require it
- **Weekly:** Clean up old packages

## Integration with Ansible Playbooks

### Current Setup:
- **VMs and PBS:** Updated/rebooted by `playbook-update-reboot.yml` (Fridays @ 1:00 AM)
- **Proxmox Hosts:** Updated/rebooted by `playbook-update-reboot.yml` (Fridays @ 1:00 AM, serially)
- **Ansible Control Node:** Updated/rebooted by `unattended-upgrades` (Saturdays @ 1:00 PM if needed)

**Schedule Timeline:**
- Friday 1:00 AM: Ansible playbook updates all VMs and Proxmox hosts
- Saturday 1:00 PM: Ansible control node reboots (if needed) - **12 hours later**

### Why <pve-2> Reboot is Safe:

Even though the ansible VM is hosted on <pve-2>, rebooting <pve-2> through ansible is safe because:

1. **Command is Queued:** Ansible sends the reboot command to <pve-2> before it actually reboots
2. **Ansible Waits:** The playbook waits for <pve-2> to come back online
3. **VM Auto-Starts:** When <pve-2> reboots, all VMs (including ansible) automatically restart
4. **Verification:** Ansible reconnects and confirms the reboot was successful

**Result:** No orphaned processes or incomplete tasks.

## Monitoring and Maintenance

### Check Last Upgrade

```bash
# View last upgrade log
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log | tail -50

# Check when last reboot occurred
last reboot
```

### Manual Force Upgrade (if needed)

```bash
# Run unattended-upgrades manually
sudo unattended-upgrades --debug

# Or use apt directly
sudo apt update && sudo apt upgrade -y
```

## Troubleshooting

### Service Not Running

```bash
sudo systemctl restart unattended-upgrades
sudo systemctl status unattended-upgrades -l
```

### Check for Errors

```bash
# Check service logs
journalctl -u unattended-upgrades -f

# Check upgrade logs
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades-dpkg.log
```

### Disable Automatic Reboot (if needed)

```bash
# Edit config
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Change to:
Unattended-Upgrade::Automatic-Reboot "false";
```

## Best Practices

1. **Monitor logs regularly:** Check `/var/log/unattended-upgrades/` weekly
2. **Test before production:** Verify reboots work as expected
3. **Set appropriate reboot time:** Scheduled for 1:00 PM (12 hours after ansible playbook)
4. **Keep inventory updated:** Document ansible control node is managed separately
5. **Backup before major updates:** Consider snapshots for critical systems
6. **Timing coordination:** Ensure 12-hour gap between playbook and control node reboot

## PBS Hosts (Debian Trixie, no sudo)

Proxmox Backup Server hosts ship without `sudo` and Ansible already
authenticates as `root` over SSH. Without intervention,
`configure-unattended-upgrades.yml` fails on the `[pbs]` group with:

```
module_stderr: /bin/sh: 1: sudo: not found
rc: 127
```

### Fix

Add a group-scoped `ansible_become` override:

```yaml
# group_vars/pbs.yml
---
ansible_become: false
```

After this, the existing playbook is fully idempotent on PBS hosts.

### Verification

```bash
ansible-playbook -i inventory configure-unattended-upgrades.yml --limit pbs
```

Expect `ok=N changed=0` once the timers, msmtp config and
`/etc/apt/apt.conf.d/50unattended-upgrades` are all in place.

### Why not just install sudo on PBS?

Standalone PBS appliances are deliberately minimal. Adding `sudo`
introduces another package + config surface (sudoers, auth log)
for no operational benefit when SSH already lands as root via
the dedicated ansible key. Disabling become for the group keeps
PBS lean and matches how it ships from upstream.

## Additional Resources

- [Ubuntu Unattended Upgrades Documentation](https://help.ubuntu.com/community/AutomaticSecurityUpdates)
- [Debian Unattended Upgrades Wiki](https://wiki.debian.org/UnattendedUpgrades)
