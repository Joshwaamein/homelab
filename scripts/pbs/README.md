# Proxmox Backup Server scripts

Operational helpers for PBS hosts.

## pbs-gc-warnings.sh

Counts `WARN` / `ERROR` / `warning` / `error` lines in the most recent
`garbage_collection` task log for a given PBS datastore. Returns an
integer (0 when the most recent GC was clean), or `-1` if called
without a datastore name.

Designed to be polled by a Zabbix `UserParameter` so the next
filesystem-corruption event surfaces as a monitoring alert rather
than as a silent dataset loss.

### Install

```bash
sudo install -m 755 -o root -g root \
    pbs-gc-warnings.sh /usr/local/bin/pbs-gc-warnings.sh

# wire to Zabbix agent 2
sudo tee /etc/zabbix/zabbix_agent2.d/pbs-gc-warnings.conf >/dev/null <<EOF2
UserParameter=pbs.gc.warnings[*],/usr/local/bin/pbs-gc-warnings.sh "\$1"
EOF2

sudo systemctl restart zabbix-agent2
zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf -t 'pbs.gc.warnings[<datastore-name>]'
```

### Background

PBS task log filenames embed the datastore name with `-` characters
encoded as the literal 4-char sequence `\x2d`. The script handles
that encoding via a small Python walk so we don't fight bash and
fnmatch escape rules.

Filed under [Vikunja #301](http://ubuntu-docker:3456/tasks/301).
