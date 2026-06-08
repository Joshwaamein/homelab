# Changelog

## [2026-06-08] - UniFi controller migration + config-ufw.yml repair

### Added
- **`group_vars/all/ufw_ports.yml`** (new) — universal UFW port
  variables. Carries `ufw_base_ports` (SSH + Zabbix Agent + Tailscale,
  per-source-scoped) plus empty-list defaults for every other
  `ufw_<group>_ports` and `ufw_*_host_ips` var the play references.
  Empty defaults stop undefined-var landmines (one of which had been
  silently triggering the rescue block on every UFW play run).
- **`group_vars/unifi_uos.yml`** (new) — port set for hosts running
  the new containerised UniFi OS Server (5.1.x+). Adds the new admin
  UI port and new guest-HTTPS port; drops the legacy admin-UI and
  legacy guest-HTTPS ports. LAN scope is the relevant management
  subnet, tailnet scope is `100.0.0.0/8`.
- **`group_vars/unifi_legacy.yml`** (new) — port set for hosts still
  running the legacy Java Network Application. Keeps the legacy
  admin-UI and legacy guest-HTTPS ports. LAN scope is the relevant
  management subnet for the legacy host's site.
- **Inventory subgroups** in `inventory.template`: `[unifi:children]`
  with `[unifi_uos]` and `[unifi_legacy]` as children so any play
  targeting the parent `unifi` (the Zabbix host-group map, etc.)
  still resolves both hosts. Live inventory patched to the same
  shape (backup at `<inventory>.bak-2026-06-08-pre-unifi-split`).

### Changed
- **`config-ufw.yml`** — base-rules block and UniFi-rules block now
  honor an optional `src` per port-list item
  (`from_ip: "{{ item.src | default('any') }}"`). Default `any` keeps
  backwards compatibility with any per-group list that doesn't carry
  `src`. Block-level `when:` clauses still gate per-group membership.
- **`config-ufw.yml`** — new "Retire deprecated UniFi rules" task that
  deletes UFW rules listed in `ufw_unifi_deprecated_ports`. Same item
  shape as the additive list. Empty default in
  `group_vars/all/ufw_ports.yml`, populated per-subgroup. Lets the
  play own the full lifecycle (add new rules + retire old ones)
  rather than relying on one-shot `ufw delete` after a migration.
- **`group_vars/unifi_uos.yml`** — populated `ufw_unifi_deprecated_ports`
  with the legacy admin UI / guest HTTPS / SSDP entries that are no
  longer needed once a host moves to the UOS Server stack
  (`8443/tcp`, `8843/tcp`, `1900/udp`, on both
  `192.168.0.0/16` and `100.0.0.0/8` source ranges).

### Audit findings (root cause of why the play had been broken)
- The fleet's UFW state had been **hand-curated, not Ansible-managed**.
  `config-ufw.yml` was non-functional in production: `ufw_base_ports`
  was undefined in any live group_vars file. The play hit
  `'ufw_base_ports' is undefined` at the first non-skipped task and
  triggered the rescue block (`Disable UFW on error`) on every run.
  Because UFW's `community.general.ufw` reports `changed` in
  `--check` mode without applying, neither dry-runs nor reviews
  caught it.
- `ufw_unifi_ports`, `ufw_mysterium_ports`, `ufw_mysterium_host_ips`,
  `ufw_pi4_host_ips` and most other per-group `ufw_*` vars were
  also undefined. They existed only in
  `group_vars/all/vault.yml.example` as a documentation stub.
  `vault.yml` itself is plain YAML (gitignored, mode 0600) and held
  only the SMTP password, no UFW data; an earlier draft of this
  entry that recommended `ansible-vault edit` was wrong.
- The `[unifi]` group held two hosts (`<unifi-vm>` running the new
  containerised UniFi OS Server, and `<unifi-pi>` still running the
  legacy Java Network Application on a Pi 3 B+). They need different
  port sets and different LAN scopes; a flat group couldn't
  represent that.

### Verified (check-mode dry-run on `--limit unifi`, 2026-06-08)
- Final recap: `failed=0, rescued=0, ignored=0` on both UniFi hosts.
  Both report `changed=4-5` for the new per-source rules the play
  would add. Existing legacy rules with broader `192.168.0.0/16`
  source scopes would remain (UFW module is additive only; cleanup
  is a separate follow-up).
- `unattended-upgrades.service` on `<unifi-vm>` remains active +
  enabled, daily timer at 05:00 BST. Origins covered: Debian +
  Ubuntu + Tailscale + Zabbix. The host OS, kernel and base
  packages will continue to receive security patches automatically.
  **The container running the new UniFi OS Server is NOT covered**
  by unattended-upgrades because it's not an apt package; that
  update path is a dedicated systemd updater service shipped with
  the container.

### Out of band (not in this repo, recorded for history)
- `<unifi-vm>` was migrated in place from the legacy Java Network
  Application to the new containerised UniFi OS Server stack on
  2026-06-08. Legacy `unifi.service` and the bundled mongod were
  stopped + disabled; an orphan mongod (forked outside the systemd
  cgroup by the legacy init script) was caught and killed manually.
  Lesson for future controller migrations: verify with
  `pgrep -au unifi`, not just `systemctl is-active unifi`.

### Follow-ups (open)
- **Master decides whether/when to actually apply `config-ufw.yml`.**
  The dry-run is clean but no apply tonight: it would add new rules
  alongside existing legacy ones, doubling rule counts. A separate
  cleanup pass (via `state: absent` task block or one-shot
  `ufw delete <rule>`) is needed to retire the redundant legacy
  rules before the play's output is the canonical state.
- **Triton-pi UniFi controller** still on the legacy stack. Options:
  retire `<unifi-pi>`'s controller role and bring the site in as a
  second site under `<unifi-vm>`'s new UniFi OS Server, or replace
  `<unifi-pi>` with a more capable host that can run UOS Server.
- **`ufw_<group>_ports` lists for all the other groups** that still
  only exist in `vault.yml.example`. The empty-list defaults in
  `group_vars/all/ufw_ports.yml` stop the play from failing, but
  per-group lists should be promoted into proper `group_vars/<group>.yml`
  files so the play actually manages those hosts' UFW state.
- **Stale rule audit on `<unifi-pi>`**: the legacy Sashimono-era
  rules (`39098`, `44840`) flagged on `<unifi-vm>` 2026-06-06 are
  also present on `<unifi-pi>` and need the same removal.

### Vikunja
- Closes the implicit "migrate `<unifi-vm>` off Network Application
  before it gets retired upstream" task.
- Suggested follow-up tickets: "promote per-group `ufw_*_ports`
  lists from vault.yml.example into real group_vars files", "audit
  + retire stale Sashimono-era UFW rules fleet-wide".

---

## [2026-05-27] - SMART Monitoring Enabled on PBS Hosts

### Added
- **`enable-smart-monitoring-pbs.yml`** — Idempotent playbook that installs
  `sudo` and `smartmontools` on the 3 PBS hosts and drops in
  `/etc/sudoers.d/zabbix-smartctl` granting the `zabbix` user `NOPASSWD`
  access to `/usr/sbin/smartctl` (the same policy already in place on
  `<pve-1/2/3>`). Validates the sudoers file with `visudo -cf`, restarts
  `zabbix-agent2`, and confirms the SMART plugin's exact call path
  (`sudo -u zabbix sudo -n smartctl --scan -j`) returns `exit_status: 0`.

### Fixed
- The `SMART by Zabbix agent 2` template was already attached to `<pbs-1/2/3>`
  but failing every LLD pass with
  `failed to scan for devices: ... exec: "sudo": executable file not found
  in $PATH`. PBS ships lean (no `sudo` package), so the agent's plugin
  could not elevate to call `smartctl`. After the playbook, the LLD on all
  3 PBS hosts cleared (`state=0`, no error) and disks started populating
  in Zabbix (`<pbs-1>`: 3 disks, `<pbs-2>`: 2 disks, `<pbs-3>`: 3 disks including the
  <USB-bridged 1TB drive> / `/dev/sdc` that backs the `<usb-datastore-name>`
  datastore).
- Bumped `Plugins.Smart.Timeout=10` (from default 3 s) on `<pbs-3>` and
  `<pve-3>` because both have USB-bridged drives whose first attribute read
  occasionally took > 0.5 s and produced a `Timeout occurred while
  gathering data.` LLD error during agent restart cycles.

### Verified
- `<pve-1/2/3>` SMART monitoring still healthy: 45/72/21 items, 48/72/24
  triggers (pre-existing).
- `<pbs-3>` post-fix: items=14 and growing, triggers=12,
  `[sdc sat]: Reallocated_Sector_Ct=0`, `Power_On_Hours=8578`,
  `Device model=<USB-bridged 1TB drive model>` visible.
- All 6 hosts (`<pve-1/2/3>` + `<pbs-1/2/3>`) now have `state=0` on the
  `smart.disk.discovery` LLD.

### Vikunja
- Closes task **#34** ("Get Zabbix to monitor SMART on PVE hosts").
- Extends task **#301** (`<pbs-3>` disk health) by giving its
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