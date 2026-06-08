# Zabbix templates

YAML exports of custom Zabbix templates used by the homelab.

## Templates

### `unattended-upgrades-by-zabbix-agent-2.yaml`

Surfaces unattended-upgrades fleet health so silent breakage (e.g. the
PBS `sudo: not found` failure caught manually on 2026-05-25) gets
flagged automatically instead of via ad-hoc audits.

Items (7), each polled every 30s by Zabbix agent 2 active checks:

| Key | Type | Purpose |
|---|---|---|
| `uu.timer.active[apt-daily-upgrade.timer]` | char | `systemctl is-active` of the install-side timer |
| `uu.timer.active[apt-daily.timer]` | char | `systemctl is-active` of the download-side timer |
| `uu.log.age` | uint64 (s) | seconds since `/var/log/unattended-upgrades/unattended-upgrades.log` was last written |
| `uu.reboot.pending.age` | uint64 (s) | seconds since `/var/run/reboot-required` appeared (0 = no reboot pending) |
| `uu.errors.recent` | uint64 | count of `ERROR` lines in current u-u log (resets weekly via logrotate) |
| `uu.config.hash` | char | sha256 of `/etc/apt/apt.conf.d/50unattended-upgrades` |
| `uu.held.count` | uint64 | `apt-mark showhold | wc -l` |

Triggers (6):

| Trigger | Severity | Condition |
|---|---|---|
| `apt-daily-upgrade.timer not active` | High | last() <> "active" |
| `apt-daily.timer not active` | Average | last() <> "active" |
| `log not written for 48h` | High | last() > 172800 |
| `reboot pending for >24h` | Average | last() > 86400 |
| `ERROR lines in unattended-upgrades log` | Average | last() > 0 |
| `50unattended-upgrades config drift` | Warning | last(#1) <> last(#2) |

UserParameters live in `templates/zabbix_agent2_uu.conf.j2` and are
deployed by `deploy-uu-zabbix-userparams.yml`. The playbook also adds
the `zabbix` user to the `adm` group so the agent can read
`/var/log/unattended-upgrades/` (mode 0750, root:adm).

Alerts route through the existing email media type (Brevo SMTP relay)
to the Admin user, mirroring the SSL fleet alert pattern.

## Importing

```bash
# Zabbix UI: Data collection > Templates > Import > select YAML file.
# Or via API:
curl -s -X POST -H "Content-Type: application/json-rpc" \
  -d '{"jsonrpc":"2.0","method":"configuration.import","params":{
    "format":"yaml",
    "rules":{"templates":{"createMissing":true,"updateExisting":true},
             "items":{"createMissing":true,"updateExisting":true},
             "triggers":{"createMissing":true,"updateExisting":true}},
    "source":"<paste yaml here>"
  },"auth":"<token>","id":1}' \
  http://zabbix.example/zabbix/api_jsonrpc.php
```

After import, link the template to your Linux host group (or per-host)
and create an Action that filters on the template + minimum severity.
