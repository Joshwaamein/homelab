# 🔧 Utility Scripts

This directory contains utility scripts for homelab management and setup.

## Available Scripts

### setup-ssh-key-on-remote-host.sh
Automates SSH key setup on remote hosts.

**What it does:**
- Generates SSH key pair if not existing (`~/.ssh/ansible`)
- Copies SSH key to remote user
- Copies key to root user with sudo
- Configures SSH securely (disables password auth)
- Restarts SSH service

**Usage:**
```bash
./setup-ssh-key-on-remote-host.sh <remote_host> <remote_user>

# Example:
./setup-ssh-key-on-remote-host.sh 192.168.1.100 ubuntu
```

**Prerequisites:**
- `sshpass` installed on local machine
- Password for remote user
- Remote host accessible via SSH

### zabbixdeploy.sh
Deploys Zabbix agent on remote hosts.

**Usage:**
```bash
./zabbixdeploy.sh
```

## Making Scripts Executable

```bash
chmod +x setup-ssh-key-on-remote-host.sh
chmod +x zabbixdeploy.sh
```

## Notes

- These scripts are standalone utilities
- For automated deployment across multiple hosts, use the Ansible playbooks in `ansible/noble-semaphore/`
- Scripts use SSH key at `~/.ssh/ansible` by default