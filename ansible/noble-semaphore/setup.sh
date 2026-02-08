#!/bin/bash
#################################################
# Ansible & Semaphore Environment Setup Script
# This script installs all dependencies needed
# for running Ansible playbooks and Semaphore
#################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ansible & Semaphore Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

echo -e "${YELLOW}Detected OS: $OS $VERSION${NC}"
echo ""

#################################################
# 1. Update System Packages
#################################################
echo -e "${GREEN}[1/8] Updating system packages...${NC}"
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt update
    apt upgrade -y
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "almalinux" ]; then
    yum update -y
fi

#################################################
# 2. Install System Dependencies
#################################################
echo -e "${GREEN}[2/8] Installing system dependencies...${NC}"
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt install -y \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        lsb-release \
        python3 \
        python3-pip \
        python3-venv \
        sshpass \
        openssh-client \
        jq
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "almalinux" ]; then
    yum install -y \
        epel-release \
        python3 \
        python3-pip \
        git \
        curl \
        wget \
        sshpass \
        openssh-clients \
        jq
fi

#################################################
# 3. Install/Upgrade Ansible
#################################################
echo -e "${GREEN}[3/8] Installing/Upgrading Ansible...${NC}"
pip3 install --upgrade ansible ansible-core

# Verify installation
ANSIBLE_VERSION=$(ansible --version | head -n1)
echo -e "${GREEN}✓ Ansible installed: $ANSIBLE_VERSION${NC}"

#################################################
# 4. Install Ansible Collections
#################################################
echo -e "${GREEN}[4/8] Installing Ansible Collections...${NC}"
cd /opt/ansible/noble-semaphore

if [ -f requirements.yml ]; then
    ansible-galaxy collection install -r requirements.yml --upgrade
    echo -e "${GREEN}✓ Collections installed${NC}"
else
    echo -e "${YELLOW}⚠ requirements.yml not found, skipping collection install${NC}"
fi

#################################################
# 5. Install Python Dependencies for Ansible
#################################################
echo -e "${GREEN}[5/8] Installing Python dependencies...${NC}"
pip3 install --upgrade \
    netaddr \
    jmespath \
    passlib \
    bcrypt \
    hvac \
    pywinrm \
    requests \
    pyyaml \
    jinja2

#################################################
# 6. Set up Semaphore Database (if needed)
#################################################
echo -e "${GREEN}[6/8] Checking Semaphore configuration...${NC}"

if [ -f /opt/semaphore/config.json ]; then
    echo -e "${GREEN}✓ Semaphore config found${NC}"
    
    # Check if Semaphore is installed
    if command -v semaphore &> /dev/null; then
        SEMAPHORE_VERSION=$(semaphore version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Semaphore installed: $SEMAPHORE_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠ Semaphore binary not found. Install from: https://github.com/ansible-semaphore/semaphore${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Semaphore config not found at /opt/semaphore/config.json${NC}"
fi

#################################################
# 7. Configure Ansible
#################################################
echo -e "${GREEN}[7/8] Configuring Ansible...${NC}"

# Create ansible directories
mkdir -p ~/.ansible/collections
mkdir -p ~/.ansible/roles
mkdir -p ~/.ansible/tmp

# Set proper permissions
chmod 755 ~/.ansible
chmod 755 /opt/ansible/noble-semaphore

echo -e "${GREEN}✓ Ansible directories configured${NC}"

#################################################
# 8. Verify Installation
#################################################
echo -e "${GREEN}[8/8] Verifying installation...${NC}"
echo ""

# Check Ansible
if command -v ansible &> /dev/null; then
    echo -e "${GREEN}✓ ansible: $(ansible --version | head -n1)${NC}"
else
    echo -e "${RED}✗ ansible not found${NC}"
fi

# Check ansible-playbook
if command -v ansible-playbook &> /dev/null; then
    echo -e "${GREEN}✓ ansible-playbook: OK${NC}"
else
    echo -e "${RED}✗ ansible-playbook not found${NC}"
fi

# Check ansible-galaxy
if command -v ansible-galaxy &> /dev/null; then
    echo -e "${GREEN}✓ ansible-galaxy: OK${NC}"
else
    echo -e "${RED}✗ ansible-galaxy not found${NC}"
fi

# Check Python
PYTHON_VERSION=$(python3 --version 2>&1)
echo -e "${GREEN}✓ Python: $PYTHON_VERSION${NC}"

# Check SSH
if command -v ssh &> /dev/null; then
    SSH_VERSION=$(ssh -V 2>&1 | head -n1)
    echo -e "${GREEN}✓ SSH: $SSH_VERSION${NC}"
else
    echo -e "${RED}✗ SSH not found${NC}"
fi

# Check collections
echo ""
echo -e "${YELLOW}Installed Ansible Collections:${NC}"
ansible-galaxy collection list | grep -E "(community.general|community.zabbix|ansible.posix)" || echo "Run: ansible-galaxy collection install -r requirements.yml"

#################################################
# 9. Final Instructions
#################################################
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "1. Create your inventory file:"
echo -e "   ${GREEN}cp inventory.template inventory${NC}"
echo -e "   ${GREEN}nano inventory${NC}"
echo ""
echo -e "2. Test Ansible connectivity:"
echo -e "   ${GREEN}ansible all -m ping${NC}"
echo ""
echo -e "3. Run a playbook:"
echo -e "   ${GREEN}ansible-playbook playbook-update-no-reboot.yml${NC}"
echo ""
echo -e "4. For vault-encrypted playbooks:"
echo -e "   ${GREEN}ansible-playbook deploy_zabbix_agent2.yaml --ask-vault-pass${NC}"
echo ""
echo -e "${YELLOW}Optional: Encrypt vault.yml for extra security${NC}"
echo -e "   ${GREEN}ansible-vault encrypt group_vars/all/vault.yml${NC}"
echo ""
echo -e "${YELLOW}Semaphore:${NC}"
echo -e "   Access at: http://localhost:3000 (if running)"
echo ""
echo -e "${GREEN}Happy automating! 🚀${NC}"