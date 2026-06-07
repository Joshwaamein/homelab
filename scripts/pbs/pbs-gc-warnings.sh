#!/bin/bash
# Count "WARN" / "warning" / "error" lines in the most recent
# garbage_collection task log for a given PBS datastore.
#
# Usage: pbs-gc-warnings.sh <datastore-name>
#
# Output: integer count of warning lines, or "-1" on error.
#
# Filed under #301: pbs3 disk health monitoring after the
# 2026-04-11 USB-bridge dropout corrupted the usb-backup
# datastore. Catch the next dropout via GC warnings rather
# than waiting for the dataset to be unrecoverable.

set -euo pipefail

DATASTORE="${1:-}"
if [[ -z "$DATASTORE" ]]; then
    echo "-1"
    exit 0
fi

# PBS encodes "-" in datastore names as the literal 4-char sequence
# \x2d in task UPID filenames. find's -name uses fnmatch, which
# treats backslash as an escape. To match a literal \ in the
# filename we need to pass two backslashes to find.
#
# Avoid bash quoting hell by walking the tasks dir with a python
# one-liner, which sees filenames as plain strings.

LATEST=$(python3 - "$DATASTORE" <<'PY'
import os, sys, glob
ds = sys.argv[1]
needle = f"garbage_collection:{ds.replace('-', r'\x2d')}:"
hits = []
for root, _, files in os.walk("/var/log/proxmox-backup/tasks/"):
    for f in files:
        if needle in f:
            full = os.path.join(root, f)
            try:
                hits.append((os.path.getmtime(full), full))
            except OSError:
                pass
if not hits:
    sys.exit(0)
hits.sort()
print(hits[-1][1])
PY
)

if [[ -z "$LATEST" ]]; then
    echo "0"  # no GC has run yet, no warnings to count
    exit 0
fi

# Count lines with "WARN" or "ERROR" or "warning" or "error".
# grep -c returns exit 1 when count is 0; suppress that so cron/Zabbix
# never see a non-zero exit.
COUNT=$(grep -ciE 'WARN|ERROR|warning|error' "$LATEST" 2>/dev/null || true)
echo "${COUNT:-0}"
