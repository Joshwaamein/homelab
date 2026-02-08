#!/usr/bin/env python3
"""
Semaphore Auto-Configuration Script
Automatically imports playbooks, inventory, SSH keys, and sets up schedules
"""

import requests
import json
import os
import sys
from pathlib import Path
from getpass import getpass

# Configuration
SEMAPHORE_URL = "http://localhost:3000"
SEMAPHORE_API = f"{SEMAPHORE_URL}/api"
PLAYBOOK_DIR = "/opt/ansible/noble-semaphore"
INVENTORY_FILE = f"{PLAYBOOK_DIR}/inventory"

# Playbook configurations with schedules
PLAYBOOKS = [
    {
        "name": "System Updates (No Reboot)",
        "playbook": "playbook-update-no-reboot.yml",
        "description": "Update packages on all systems without rebooting",
        "schedule": "0 2 * * 0",  # Every Sunday at 2 AM
        "schedule_name": "Weekly Updates"
    },
    {
        "name": "System Updates with Reboot",
        "playbook": "playbook-update-reboot.yml",
        "description": "Update packages and reboot if kernel updated",
        "schedule": "0 3 1 * *",  # First day of month at 3 AM
        "schedule_name": "Monthly Updates with Reboot"
    },
    {
        "name": "Deploy Zabbix Agent 2",
        "playbook": "deploy_zabbix_agent2.yaml",
        "description": "Deploy or upgrade Zabbix Agent 2 monitoring",
        "schedule": None  # Manual only
    },
    {
        "name": "Configure Fail2ban",
        "playbook": "config-f2b-protect-sshd.yaml",
        "description": "Install and configure Fail2ban for SSH protection",
        "schedule": None  # Manual only
    },
    {
        "name": "Configure UFW Firewall",
        "playbook": "config-ufw.yml",
        "description": "Configure UFW firewall with safety checks",
        "schedule": None  # Manual only (dangerous)
    },
    {
        "name": "Secure SSH Configuration",
        "playbook": "secure_ssh_configuration.yml",
        "description": "Harden SSH configuration",
        "schedule": None  # Manual only (dangerous)
    },
    {
        "name": "Install QEMU Guest Agent",
        "playbook": "install-qemu-guest-agent.yml",
        "description": "Install QEMU guest agent on VMs",
        "schedule": None  # Manual only
    },
    {
        "name": "Set Timezone",
        "playbook": "set_timezone_noble_network.yml",
        "description": "Configure timezone across all hosts",
        "schedule": None  # Manual only
    },
    {
        "name": "Get All Usernames",
        "playbook": "get-all-usernames.yml",
        "description": "Generate report of users across all systems",
        "schedule": "0 0 * * 1",  # Every Monday at midnight
        "schedule_name": "Weekly User Report"
    },
    {
        "name": "Deploy Zabbix Agent (Role)",
        "playbook": "tailscale-net-zabbix-agent-playbook.yml",
        "description": "Install Zabbix Agent using community role",
        "schedule": None  # Manual only
    }
]

class SemaphoreConfigurator:
    def __init__(self, url, username, password):
        self.url = url
        self.api = f"{url}/api"
        self.session = requests.Session()
        self.username = username
        self.password = password
        self.token = None
        self.user_id = None
        self.project_id = None
        
    def login(self):
        """Authenticate with Semaphore"""
        print("🔐 Logging in to Semaphore...")
        response = self.session.post(
            f"{self.api}/auth/login",
            json={
                "auth": self.username,
                "password": self.password
            }
        )
        
        if response.status_code == 204:
            print("✅ Successfully authenticated")
            # Get user info
            user_response = self.session.get(f"{self.api}/user")
            if user_response.status_code == 200:
                self.user_id = user_response.json()["id"]
                print(f"   User ID: {self.user_id}")
            return True
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(response.text)
            return False
    
    def create_project(self, name="Ansible Automation"):
        """Create or get project"""
        print(f"\n📁 Creating/finding project: {name}")
        
        # Check if project exists
        response = self.session.get(f"{self.api}/projects")
        if response.status_code == 200:
            projects = response.json()
            for project in projects:
                if project["name"] == name:
                    self.project_id = project["id"]
                    print(f"✅ Found existing project (ID: {self.project_id})")
                    return True
        
        # Create new project
        response = self.session.post(
            f"{self.api}/projects",
            json={
                "name": name,
                "alert": False,
                "alert_chat": None,
                "max_parallel_tasks": 3
            }
        )
        
        if response.status_code in [200, 201]:
            self.project_id = response.json()["id"]
            print(f"✅ Created new project (ID: {self.project_id})")
            return True
        else:
            print(f"❌ Failed to create project: {response.status_code}")
            return False
    
    def create_key(self, name, ssh_key_path):
        """Create SSH key in Semaphore"""
        print(f"\n🔑 Importing SSH key: {name}")
        
        if not os.path.exists(ssh_key_path):
            print(f"⚠️  SSH key not found: {ssh_key_path}")
            return None
        
        with open(ssh_key_path, 'r') as f:
            key_content = f.read()
        
        # Check if key exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/keys")
        if response.status_code == 200:
            keys = response.json()
            for key in keys:
                if key["name"] == name:
                    print(f"✅ SSH key already exists (ID: {key['id']})")
                    return key["id"]
        
        # Create new key
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/keys",
            json={
                "name": name,
                "type": "ssh",
                "project_id": self.project_id,
                "secret": key_content
            }
        )
        
        if response.status_code in [200, 201]:
            key_id = response.json()["id"]
            print(f"✅ Imported SSH key (ID: {key_id})")
            return key_id
        else:
            print(f"❌ Failed to import SSH key: {response.status_code}")
            return None
    
    def create_inventory(self, name, inventory_path):
        """Create inventory in Semaphore"""
        print(f"\n📋 Importing inventory: {name}")
        
        if not os.path.exists(inventory_path):
            print(f"⚠️  Inventory file not found: {inventory_path}")
            print(f"   Please copy inventory.template to inventory first")
            return None
        
        with open(inventory_path, 'r') as f:
            inventory_content = f.read()
        
        # Check if inventory exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/inventory")
        if response.status_code == 200:
            inventories = response.json()
            for inv in inventories:
                if inv["name"] == name:
                    print(f"✅ Inventory already exists (ID: {inv['id']})")
                    return inv["id"]
        
        # Create new inventory
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/inventory",
            json={
                "name": name,
                "project_id": self.project_id,
                "inventory": inventory_content,
                "type": "static"
            }
        )
        
        if response.status_code in [200, 201]:
            inv_id = response.json()["id"]
            print(f"✅ Imported inventory (ID: {inv_id})")
            return inv_id
        else:
            print(f"❌ Failed to import inventory: {response.status_code}")
            print(response.text)
            return None
    
    def create_repository(self, name, path):
        """Create repository (local path)"""
        print(f"\n📦 Creating repository: {name}")
        
        # Check if repository exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/repositories")
        if response.status_code == 200:
            repos = response.json()
            for repo in repos:
                if repo["name"] == name:
                    print(f"✅ Repository already exists (ID: {repo['id']})")
                    return repo["id"]
        
        # Create new repository
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/repositories",
            json={
                "name": name,
                "project_id": self.project_id,
                "git_url": f"file://{path}",
                "ssh_key_id": None
            }
        )
        
        if response.status_code in [200, 201]:
            repo_id = response.json()["id"]
            print(f"✅ Created repository (ID: {repo_id})")
            return repo_id
        else:
            print(f"❌ Failed to create repository: {response.status_code}")
            print(response.text)
            return None
    
    def create_environment(self, name):
        """Create environment for variables"""
        print(f"\n🌍 Creating environment: {name}")
        
        # Check if environment exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/environment")
        if response.status_code == 200:
            envs = response.json()
            for env in envs:
                if env["name"] == name:
                    print(f"✅ Environment already exists (ID: {env['id']})")
                    return env["id"]
        
        # Create new environment
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/environment",
            json={
                "name": name,
                "project_id": self.project_id,
                "json": "{}",
                "env": None
            }
        )
        
        if response.status_code in [200, 201]:
            env_id = response.json()["id"]
            print(f"✅ Created environment (ID: {env_id})")
            return env_id
        else:
            print(f"❌ Failed to create environment: {response.status_code}")
            return None
    
    def create_template(self, playbook_config, inventory_id, repo_id, env_id, key_id):
        """Create template (playbook) in Semaphore"""
        name = playbook_config["name"]
        print(f"\n📝 Creating template: {name}")
        
        # Check if template exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/templates")
        if response.status_code == 200:
            templates = response.json()
            for template in templates:
                if template["name"] == name:
                    print(f"✅ Template already exists (ID: {template['id']})")
                    return template["id"]
        
        # Create new template
        template_data = {
            "project_id": self.project_id,
            "inventory_id": inventory_id,
            "repository_id": repo_id,
            "environment_id": env_id,
            "name": name,
            "playbook": playbook_config["playbook"],
            "arguments": "[]",
            "description": playbook_config["description"],
            "allow_override_args_in_task": False,
            "limit": "",
            "suppress_success_alerts": True,
            "survey_vars": None,
            "type": "",
            "start_version": "",
            "app": "",
            "autorun": False
        }
        
        if key_id:
            template_data["vault_key_id"] = key_id
        
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/templates",
            json=template_data
        )
        
        if response.status_code in [200, 201]:
            template_id = response.json()["id"]
            print(f"✅ Created template (ID: {template_id})")
            return template_id
        else:
            print(f"❌ Failed to create template: {response.status_code}")
            print(response.text)
            return None
    
    def create_schedule(self, template_id, playbook_config):
        """Create schedule for template"""
        if not playbook_config.get("schedule"):
            return None
        
        schedule_name = playbook_config.get("schedule_name", "Auto Schedule")
        cron_format = playbook_config["schedule"]
        
        print(f"⏰ Creating schedule: {schedule_name} ({cron_format})")
        
        # Check if schedule exists
        response = self.session.get(f"{self.api}/project/{self.project_id}/schedules")
        if response.status_code == 200:
            schedules = response.json()
            for sched in schedules:
                if sched["template_id"] == template_id:
                    print(f"✅ Schedule already exists (ID: {sched['id']})")
                    return sched["id"]
        
        # Create new schedule
        response = self.session.post(
            f"{self.api}/project/{self.project_id}/schedules",
            json={
                "project_id": self.project_id,
                "template_id": template_id,
                "cron_format": cron_format,
                "name": schedule_name,
                "active": True
            }
        )
        
        if response.status_code in [200, 201]:
            schedule_id = response.json()["id"]
            print(f"✅ Created schedule (ID: {schedule_id})")
            return schedule_id
        else:
            print(f"❌ Failed to create schedule: {response.status_code}")
            return None
    
    def configure_all(self):
        """Main configuration workflow"""
        print("=" * 60)
        print("🚀 Semaphore Auto-Configuration")
        print("=" * 60)
        
        # 1. Login
        if not self.login():
            return False
        
        # 2. Create/get project
        if not self.create_project():
            return False
        
        # 3. Import SSH key
        ssh_key_path = os.path.expanduser("~/.ssh/id_rsa")
        key_id = self.create_key("Default SSH Key", ssh_key_path)
        
        # 4. Import inventory
        inventory_id = self.create_inventory("Main Inventory", INVENTORY_FILE)
        if not inventory_id:
            print("\n⚠️  Cannot proceed without inventory file")
            print(f"   Please run: cp {PLAYBOOK_DIR}/inventory.template {INVENTORY_FILE}")
            return False
        
        # 5. Create repository
        repo_id = self.create_repository("Ansible Playbooks", PLAYBOOK_DIR)
        if not repo_id:
            return False
        
        # 6. Create environment
        env_id = self.create_environment("Production")
        if not env_id:
            return False
        
        # 7. Create templates for all playbooks
        print("\n" + "=" * 60)
        print("📝 Creating playbook templates...")
        print("=" * 60)
        
        created_count = 0
        scheduled_count = 0
        
        for playbook in PLAYBOOKS:
            template_id = self.create_template(
                playbook, inventory_id, repo_id, env_id, key_id
            )
            
            if template_id:
                created_count += 1
                
                # Create schedule if specified
                if playbook.get("schedule"):
                    schedule_id = self.create_schedule(template_id, playbook)
                    if schedule_id:
                        scheduled_count += 1
        
        # Summary
        print("\n" + "=" * 60)
        print("✅ Configuration Complete!")
        print("=" * 60)
        print(f"📊 Summary:")
        print(f"   - Project ID: {self.project_id}")
        print(f"   - Playbooks imported: {created_count}")
        print(f"   - Schedules created: {scheduled_count}")
        print(f"\n🌐 Access Semaphore at: {self.url}")
        print("=" * 60)
        
        return True

def main():
    print("\n🔧 Semaphore Auto-Configuration Tool")
    print("=" * 60)
    
    # Get credentials
    username = input("Enter Semaphore username (default: admin): ").strip() or "admin"
    password = getpass("Enter Semaphore password: ")
    
    if not password:
        print("❌ Password is required")
        sys.exit(1)
    
    # Create configurator
    configurator = SemaphoreConfigurator(SEMAPHORE_URL, username, password)
    
    # Run configuration
    success = configurator.configure_all()
    
    if success:
        print("\n✅ All done! Your playbooks are now configured in Semaphore.")
        print("\n📝 Schedules configured:")
        print("   - Weekly Updates: Every Sunday at 2 AM")
        print("   - Monthly Updates with Reboot: 1st of month at 3 AM")
        print("   - Weekly User Report: Every Monday at midnight")
        sys.exit(0)
    else:
        print("\n❌ Configuration failed. Check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()