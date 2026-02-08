# Ansible Automation Repository

This repository contains Ansible playbooks and configuration files for managing infrastructure.

## Structure

```
/opt/
├── ansible/
│   └── noble-semaphore/          # Main playbooks directory
│       ├── inventory.template    # Template for creating your inventory
│       ├── *.yml                 # Ansible playbooks
│       ├── configfiles/          # Configuration file templates
│       └── homelab/              # Homelab-specific scripts
└── semaphore/                    # Semaphore configuration (not tracked)
```

## Setup

1. **Create your inventory file:**
   ```bash
   cp ansible/noble-semaphore/inventory.template ansible/noble-semaphore/inventory
   ```

2. **Edit the inventory file** with your actual hosts and IPs.

3. **Run playbooks:**
   ```bash
   ansible-playbook -i ansible/noble-semaphore/inventory ansible/noble-semaphore/<playbook-name>.yml
   ```

## Available Playbooks

- `config-f2b-protect-sshd.yaml` - Configure Fail2Ban for SSH protection
- `config-ufw.yml` - Configure UFW firewall
- `deploy_zabbix_agent2.yaml` - Deploy Zabbix Agent 2
- `install-qemu-guest-agent.yml` - Install QEMU guest agent
- `playbook-update-no-reboot.yml` - Update systems without reboot
- `playbook-update-reboot.yml` - Update systems with reboot
- `secure_ssh_configuration.yml` - Secure SSH configuration
- `set_timezone_noble_network.yml` - Set timezone on hosts
- `tailscale-net-zabbix-agent-playbook.yml` - Configure Tailscale network with Zabbix

## Security

**IMPORTANT:** The following files are excluded from version control for security:
- `inventory` - Contains real IPs and hostnames
- `users.txt` - Contains user information
- Personal configuration files in `semaphore/`
- Logs and temporary files

Always use the `inventory.template` as a reference and keep your actual `inventory` file private.

## Contributing

When adding new playbooks, ensure they follow Ansible best practices and include appropriate comments.