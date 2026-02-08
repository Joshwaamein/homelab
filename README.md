# Ansible Automation Repository

This repository contains Ansible playbooks and configuration files for managing infrastructure across multiple environments.

## 🎯 Quick Start

### Automated Setup (Recommended)

```bash
# Run the setup script to install all dependencies
cd /opt/ansible/noble-semaphore
sudo ./setup.sh
```

The setup script will:
- Install Ansible and required system packages
- Install Python dependencies
- Install Ansible collections
- Configure Ansible directories
- Verify the installation

### Manual Setup

```bash
# 1. Clone the repository
cd /opt/ansible/noble-semaphore

# 2. Install required collections
ansible-galaxy collection install -r requirements.yml

# 3. Create your inventory from template
cp inventory.template inventory

# 4. Edit inventory with your actual hosts
nano inventory

# 5. (Optional) Encrypt vault.yml for extra security
ansible-vault encrypt group_vars/all/vault.yml

# 6. Run a playbook
ansible-playbook playbook-update-no-reboot.yml
```
│   └── zabbix_agent2.conf.j2    # Zabbix agent config template
├── configfiles/
│   └── debian-sshd-default.conf  # Fail2ban config
└── *.yml                         # Ansible playbooks
```

## 🔒 Security Setup

### Vault Configuration (Zero Overhead)

The `vault.yml` file is already configured with your credentials and is **ready to use immediately** - no encryption needed!

**Current Setup:**
- ✅ vault.yml contains your credentials (default Zabbix password)
- ✅ Already excluded from git via .gitignore
- ✅ Works with ALL playbooks - no `--ask-vault-pass` needed
- ✅ **Zero overhead** - just run playbooks normally

```bash
# Run playbooks directly - no extra flags needed
ansible-playbook deploy_zabbix_agent2.yaml
ansible-playbook playbook-update-no-reboot.yml
```

### Optional: Encrypt Vault (Only if needed)

If you change the default passwords or want extra security:

```bash
# Encrypt vault.yml
ansible-vault encrypt group_vars/all/vault.yml

# Then run playbooks with:
ansible-playbook playbook-name.yml --ask-vault-pass

# Edit encrypted vault:
ansible-vault edit group_vars/all/vault.yml
```

### What's Protected from Git

The following files are automatically excluded from git:
- `inventory` - Contains real IPs and hostnames
- `users.txt` - Contains user information
- `**/vault.yml` - Your credentials (encrypted or not)
- `semaphore/` - Semaphore runtime data

## 📚 Available Playbooks

### System Maintenance

#### `playbook-update-no-reboot.yml`
Update packages without rebooting.
```bash
ansible-playbook playbook-update-no-reboot.yml
```

#### `playbook-update-reboot.yml`
Update packages and reboot if kernel was updated.
```bash
ansible-playbook playbook-update-reboot.yml
```

### Security Configuration

#### `secure_ssh_configuration.yml`
Harden SSH configuration with safety checks.
- ✅ Verifies SSH keys exist before disabling password auth
- ✅ Backs up current config
- ✅ Validates configuration before applying

```bash
ansible-playbook secure_ssh_configuration.yml
```

**⚠️ WARNING:** Only run after ensuring SSH keys are deployed!

#### `config-f2b-protect-sshd.yaml`
Install and configure Fail2ban for SSH protection.
```bash
ansible-playbook config-f2b-protect-sshd.yaml
```

#### `config-ufw.yml`
Configure UFW firewall with safety checks.
- ✅ Ensures SSH is allowed before enabling firewall
- ✅ Application-specific rules
- ✅ Automatic rollback on error

```bash
ansible-playbook config-ufw.yml
```

**⚠️ WARNING:** This playbook modifies firewall rules. Review before running!

### Monitoring

#### `deploy_zabbix_agent2.yaml`
Deploy Zabbix Agent 2 for monitoring.
- Uses variables from `group_vars/all/vars.yml`
- Credentials from `group_vars/all/vault.yml`

```bash
ansible-playbook deploy_zabbix_agent2.yaml
```

#### `tailscale-net-zabbix-agent-playbook.yml`
Install Zabbix Agent using community role.
```bash
ansible-playbook tailscale-net-zabbix-agent-playbook.yml
```

### Utilities

#### `install-qemu-guest-agent.yml`
Install QEMU Guest Agent on virtual machines.
```bash
ansible-playbook install-qemu-guest-agent.yml
```

#### `set_timezone_noble_network.yml`
Configure timezone across all hosts.
```bash
ansible-playbook set_timezone_noble_network.yml
```

#### `get-all-usernames.yml`
Generate report of users across all systems.
```bash
ansible-playbook get-all-usernames.yml
```
Output: `/opt/ansible/users.txt` (not tracked in git)

## ⚙️ Configuration Variables

Edit `group_vars/all/vars.yml` to customize:

```yaml
# Zabbix Configuration
zabbix_server_ip: "100.85.45.123"
zabbix_version: "7.0"

# Timezone Configuration
timezone: "Europe/London"

# SSH Configuration
ssh_permit_root_login: "prohibit-password"
ssh_password_authentication: false
```

Edit `group_vars/all/vault.yml` for secrets:

```yaml
# Zabbix Credentials (encrypted)
zabbix_admin_user: "Admin"
zabbix_admin_password: "your-secure-password"
```

## 🚀 Running Playbooks

### Basic Usage
```bash
ansible-playbook playbook-name.yml
```

### With Vault Password
```bash
ansible-playbook playbook-name.yml --ask-vault-pass
```

### Limit to Specific Hosts
```bash
ansible-playbook playbook-name.yml --limit "host1,host2"
```

### Check Mode (Dry Run)
```bash
ansible-playbook playbook-name.yml --check
```

### With Tags
```bash
ansible-playbook playbook-name.yml --tags "install,config"
```

## 🔧 Inventory Management

Your inventory file defines hosts and groups:

```ini
[ubuntu_vms]
100.119.2.84        # server1
100.117.7.21        # server2

[evernode]
100.119.2.84        # server1

[proxmox]
100.96.81.60        # pve1
```

## 🛠️ Development Workflow

### Before Committing Changes

1. **Never commit secrets**
   ```bash
   git status  # Verify no sensitive files staged
   ```

2. **Test playbooks**
   ```bash
   ansible-playbook playbook-name.yml --check
   ```

3. **Validate syntax**
   ```bash
   ansible-playbook playbook-name.yml --syntax-check
   ```

### Making Changes

1. Edit playbooks in your favorite editor
2. Test in check mode first
3. Run on a test host
4. Commit to git (without secrets!)

## 📋 Best Practices

### ✅ DO
- Use variables from `group_vars/`
- Store secrets in Ansible Vault
- Test with `--check` before running
- Use `ignore_unreachable: true` for large environments
- Add comments to your inventory
- Use specific versions in requirements.yml

### ❌ DON'T
- Hardcode passwords in playbooks
- Commit inventory with real IPs
- Disable firewall without SSH backup rule
- Disable SSH password auth without key verification
- Run destructive playbooks without testing

## 🐛 Troubleshooting

### Playbook Fails with "Permission Denied"
```bash
# Ensure you can SSH to hosts
ssh user@host

# Check ansible connectivity
ansible all -m ping
```

### Vault Password Issues
```bash
# Reset vault password
ansible-vault rekey group_vars/all/vault.yml
```

### SSH Connection Timeout
```bash
# Test with verbose mode
ansible-playbook playbook-name.yml -vvv
```

### UFW Lockout
If you get locked out after UFW configuration:
1. Access via console (not SSH)
2. Run: `sudo ufw disable`
3. Fix rules, then re-enable

## 📊 Monitoring & Reporting

- Zabbix monitoring via agents on all hosts
- User reports generated to `/opt/ansible/users.txt`
- Playbook execution logs in Semaphore

## 🔄 Updates & Maintenance

### Update Collections
```bash
ansible-galaxy collection install -r requirements.yml --upgrade
```

### Update Playbooks
```bash
git pull origin main
```

## 🤝 Contributing

When adding new playbooks:

1. Follow existing naming conventions
2. Use FQCN (Fully Qualified Collection Names): `ansible.builtin.copy`
3. Add appropriate error handling
4. Document in this README
5. Test thoroughly before committing

## 📝 Changelog

### 2026-02-08 - Major Refactoring
- ✅ Removed hardcoded credentials from playbooks
- ✅ Added Ansible Vault support
- ✅ Created group_vars structure
- ✅ Added safety checks to SSH and UFW playbooks
- ✅ Replaced shell commands with proper modules
- ✅ Added requirements.yml for collections
- ✅ Created ansible.cfg with optimizations
- ✅ Improved error handling across all playbooks
- ✅ Added comprehensive documentation

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review Ansible documentation: https://docs.ansible.com
- Check playbook syntax: `ansible-playbook playbook-name.yml --syntax-check`

## 📜 License

Internal use only - Noble Network Infrastructure

---

**⚠️ SECURITY REMINDER:** This repository manages critical infrastructure. Always:
- Review changes before applying
- Test in non-production first
- Keep vault passwords secure
- Never commit sensitive data