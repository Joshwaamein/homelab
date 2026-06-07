#!/bin/bash

echo "== Checking ReputationD service status =="
sudo -u sashireputationd XDG_RUNTIME_DIR="/run/user/$(id -u sashireputationd)" systemctl --user status sashimono-reputationd.service

echo "== Recent ReputationD logs =="
sudo -u sashireputationd bash -c 'journalctl --user -u sashimono-reputationd | tail -n 50'

echo "== Evernode contracts running =="
evernode list

echo "== HotPocket consensus logs (replace <user> and <name> accordingly) =="
# cat /home/<user>/<name>/log/hp.log | grep "Ledger created"

echo "== Contract logs (replace <user> and <name> accordingly) =="
# cat /home/<user>/<name>/log/contract/rw.stdout.log
# cat /home/<user>/<name>/log/contract/rw.stderr.log

echo "== Reputation reporting logs =="
sudo -u sashireputationd bash -c 'journalctl --user -u sashimono-reputationd | grep "Reporting"'

echo "== IPv4 support =="
ip a | grep inet

echo "== Resource usage and limits =="
free -m

echo "== Lease offers =="
evernode offerlease

echo "== Evernode reputation status =="
evernode reputationd status

echo "== Evernode host status =="
evernode status

