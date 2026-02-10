#!/bin/bash
#
# SSH Key Setup Script - Production Version
# 
# Purpose: Automates SSH key deployment to remote hosts with safety checks
# Usage: ./setup-ssh-key-on-remote-host.sh <remote_host> <remote_user>
#
# Features:
# - Proper error handling and validation
# - Backup of remote sshd_config before changes
# - Verification of SSH key before disabling password auth
# - Dependency checking
# - Color-coded output and logging
# - Early detection of existing SSH keys
#
# Author: Homelab Automation
# Version: 2.2

set -uo pipefail  # Exit on undefined vars, pipe failures (but not on error to handle failures gracefully)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (can be overridden by environment variables)
SSH_KEY="${SSH_KEY:-$HOME/.ssh/ansible}"
BACKUP_DIR="$HOME/.ssh/backups"
SSH_TIMEOUT=5

# Script info
SCRIPT_NAME=$(basename "$0")
VERSION="2.2"

#==============================================================================
# Helper Functions
#==============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_usage() {
    cat << EOF
${BLUE}SSH Key Setup Script v${VERSION}${NC}

${GREEN}Usage:${NC}
    $SCRIPT_NAME <remote_host> <remote_user>

${GREEN}Examples:${NC}
    $SCRIPT_NAME 192.168.1.100 ubuntu
    $SCRIPT_NAME server1.local admin

${GREEN}Environment Variables:${NC}
    SSH_KEY    - Path to SSH key (default: ~/.ssh/ansible)

${GREEN}Features:${NC}
    ✓ Generates ed25519 SSH key if not exists
    ✓ Copies key to remote user
    ✓ Copies key to root with sudo
    ✓ Backs up remote sshd_config
    ✓ Verifies key before disabling passwords
    ✓ Configures SSH securely

${GREEN}Prerequisites:${NC}
    - sshpass installed (sudo apt install sshpass)
    - SSH access to remote host
    - Sudo privileges on remote host

EOF
}

check_dependencies() {
    log_step "Checking dependencies..."
    
    local missing=()
    local deps=("sshpass" "ssh-keygen" "ssh" "ssh-copy-id")
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Install with: sudo apt install sshpass openssh-client"
        exit 1
    fi
    
    log_success "All dependencies present"
}

validate_arguments() {
    if [ $# -ne 2 ]; then
        log_error "Invalid number of arguments"
        echo ""
        show_usage
        exit 1
    fi
    
    REMOTE_HOST=$1
    REMOTE_USER=$2
    
    # Basic validation
    if [[ -z "$REMOTE_HOST" ]] || [[ -z "$REMOTE_USER" ]]; then
        log_error "Host and user cannot be empty"
        exit 1
    fi
    
    log_success "Arguments validated"
}

check_host_reachable() {
    log_step "Checking if host is reachable..."
    
    if ping -c 1 -W 2 "$REMOTE_HOST" &>/dev/null; then
        log_success "Host $REMOTE_HOST is reachable"
        return 0
    else
        log_warn "Cannot ping $REMOTE_HOST"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
    fi
}

generate_ssh_key() {
    log_step "Checking SSH key..."
    
    if [ -f "$SSH_KEY" ]; then
        log_info "SSH key already exists at $SSH_KEY"
        return 0
    fi
    
    log_info "Generating new ed25519 SSH key..."
    mkdir -p "$(dirname "$SSH_KEY")"
    
    if ssh-keygen -q -t ed25519 -f "$SSH_KEY" -N "" -C "ansible@$(hostname)"; then
        log_success "SSH key generated: $SSH_KEY"
    else
        log_error "Failed to generate SSH key"
        exit 1
    fi
}

check_existing_key_on_remote() {
    log_step "Checking if SSH key already exists on remote host..."
    
    # First try with key-based auth (no password)
    if ssh -i "$SSH_KEY" \
        -o BatchMode=yes \
        -o ConnectTimeout=$SSH_TIMEOUT \
        -o StrictHostKeyChecking=accept-new \
        "$REMOTE_USER@$REMOTE_HOST" "exit" &>/dev/null; then
        log_success "SSH key authentication already working!"
        log_info "Host: $REMOTE_HOST"
        log_info "User: $REMOTE_USER"
        echo ""
        log_warn "The SSH key is already configured on this host."
        
        # Check if we can access as root too
        if ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=$SSH_TIMEOUT \
            "root@$REMOTE_HOST" "exit" &>/dev/null; then
            log_success "Root SSH access also working"
        else
            log_info "Root SSH access not configured"
        fi
        
        echo ""
        read -p "Do you want to reconfigure anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Nothing to do. Exiting."
            exit 0
        else
            log_warn "Proceeding with reconfiguration..."
            return 1  # Signal that we need password
        fi
    fi
    
    return 1  # Key doesn't work, need to continue with password
}

get_remote_password() {
    log_step "Getting remote password..."
    
    # Prompt for password securely
    read -s -p "Enter password for $REMOTE_USER@$REMOTE_HOST: " REMOTE_PASS
    echo
    
    if [[ -z "$REMOTE_PASS" ]]; then
        log_error "Password cannot be empty"
        exit 1
    fi
    
    log_success "Password received"
}

copy_ssh_key_to_user() {
    log_step "Copying SSH key to $REMOTE_USER@$REMOTE_HOST..."
    
    if sshpass -p "$REMOTE_PASS" ssh-copy-id \
        -o ConnectTimeout=$SSH_TIMEOUT \
        -o StrictHostKeyChecking=accept-new \
        -i "$SSH_KEY.pub" \
        "$REMOTE_USER@$REMOTE_HOST" &>/dev/null; then
        log_success "SSH key copied to user $REMOTE_USER"
        return 0
    else
        log_error "Failed to copy SSH key to user"
        log_error "Possible reasons:"
        log_error "  - Incorrect password"
        log_error "  - SSH service not running"
        log_error "  - Network connectivity issues"
        exit 1
    fi
}

verify_ssh_key_works() {
    log_step "Verifying SSH key authentication..."
    
    if ssh -i "$SSH_KEY" \
        -o BatchMode=yes \
        -o ConnectTimeout=$SSH_TIMEOUT \
        -o StrictHostKeyChecking=accept-new \
        "$REMOTE_USER@$REMOTE_HOST" "exit" &>/dev/null; then
        log_success "SSH key authentication working for $REMOTE_USER"
        return 0
    else
        log_error "SSH key authentication failed"
        log_error "Cannot proceed safely. Please check the setup."
        exit 1
    fi
}

backup_remote_sshd_config() {
    log_step "Backing up remote sshd_config..."
    
    local backup_name="sshd_config.backup.$(date +%Y%m%d-%H%M%S)"
    
    # Determine if we need sudo or not
    local SUDO_CMD=""
    if [ "$REMOTE_USER" != "root" ]; then
        SUDO_CMD="sudo"
    fi
    
    if ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" \
        "$SUDO_CMD cp /etc/ssh/sshd_config /etc/ssh/$backup_name" 2>/dev/null; then
        log_success "Backup created: /etc/ssh/$backup_name"
        return 0
    else
        log_warn "Could not backup sshd_config (continuing anyway)"
        return 1
    fi
}

setup_root_access() {
    log_step "Setting up root SSH access..."
    
    # Check if we're already root
    if [ "$REMOTE_USER" = "root" ]; then
        log_info "Already logged in as root, skipping root access setup"
        return 0
    fi
    
    # Use SSH key to run commands on remote host
    ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" bash << 'ENDSSH'
        # Create root .ssh directory
        echo "Creating /root/.ssh directory..."
        sudo mkdir -p /root/.ssh
        
        # Copy authorized_keys to root
        echo "Copying SSH key to root..."
        sudo cp ~/.ssh/authorized_keys /root/.ssh/
        
        # Set proper permissions
        echo "Setting permissions..."
        sudo chmod 700 /root/.ssh
        sudo chmod 600 /root/.ssh/authorized_keys
        sudo chown root:root /root/.ssh/authorized_keys
        
        echo "Root SSH access configured"
ENDSSH
    
    if [ $? -eq 0 ]; then
        log_success "Root SSH access configured"
    else
        log_error "Failed to configure root access"
        exit 1
    fi
}

verify_root_access() {
    log_step "Verifying root SSH access..."
    
    if ssh -i "$SSH_KEY" \
        -o BatchMode=yes \
        -o ConnectTimeout=$SSH_TIMEOUT \
        "root@$REMOTE_HOST" "exit" &>/dev/null; then
        log_success "Root SSH key authentication working"
        return 0
    else
        log_warn "Root SSH key authentication failed"
        log_warn "You may need to configure root access manually"
        return 1
    fi
}

configure_secure_ssh() {
    log_step "Configuring secure SSH settings..."
    
    # Determine if we need sudo or not
    local SUDO_CMD=""
    if [ "$REMOTE_USER" != "root" ]; then
        SUDO_CMD="sudo"
    fi
    
    ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" bash << ENDSSH
        # Backup current config (again, just to be safe)
        $SUDO_CMD cp /etc/ssh/sshd_config /etc/ssh/sshd_config.pre-hardening
        
        # Configure SSH securely
        echo "Updating SSH configuration..."
        $SUDO_CMD sed -i.bak 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        $SUDO_CMD sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        $SUDO_CMD sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        $SUDO_CMD sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
        
        # Test configuration
        echo "Testing SSH configuration..."
        if $SUDO_CMD sshd -t; then
            echo "Configuration valid"
            # Restart SSH service
            echo "Restarting SSH service..."
            $SUDO_CMD systemctl restart sshd || $SUDO_CMD systemctl restart ssh
            echo "SSH service restarted"
        else
            echo "ERROR: Invalid SSH configuration!"
            echo "Restoring backup..."
            $SUDO_CMD cp /etc/ssh/sshd_config.pre-hardening /etc/ssh/sshd_config
            exit 1
        fi
ENDSSH
    
    if [ $? -eq 0 ]; then
        log_success "SSH securely configured"
    else
        log_error "Failed to configure SSH securely"
        log_error "Your SSH config has been restored from backup"
        exit 1
    fi
}

final_verification() {
    log_step "Performing final verification..."
    
    local success=true
    
    # Test user access
    if ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 \
        "$REMOTE_USER@$REMOTE_HOST" "exit" &>/dev/null; then
        log_success "User SSH access: OK"
    else
        log_error "User SSH access: FAILED"
        success=false
    fi
    
    # Test root access
    if ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 \
        "root@$REMOTE_HOST" "exit" &>/dev/null; then
        log_success "Root SSH access: OK"
    else
        log_warn "Root SSH access: Not working (this may be intentional)"
    fi
    
    if [ "$success" = false ]; then
        log_error "Verification failed!"
        exit 1
    fi
}

show_completion_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Setup completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "SSH Key Location: $SSH_KEY"
    log_info "Remote Host: $REMOTE_HOST"
    log_info "Remote User: $REMOTE_USER"
    echo ""
    log_info "Test your connection:"
    echo "  ${GREEN}ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST${NC}"
    echo "  ${GREEN}ssh -i $SSH_KEY root@$REMOTE_HOST${NC}"
    echo ""
    log_info "Add to your Ansible inventory:"
    echo "  $REMOTE_HOST ansible_user=$REMOTE_USER ansible_ssh_private_key_file=$SSH_KEY"
    echo ""
    log_warn "Important: Password authentication is now DISABLED"
    log_warn "Make sure you have your SSH key backed up!"
    echo ""
}

#==============================================================================
# Main Script
#==============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BLUE}SSH Key Setup Script v${VERSION}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Validate arguments
    validate_arguments "$@"
    
    # Pre-flight checks
    check_dependencies
    check_host_reachable
    generate_ssh_key
    
    # Check if key already exists on remote (will exit if already configured)
    check_existing_key_on_remote
    NEED_PASSWORD=$?
    
    # Only get password if we need it
    if [ $NEED_PASSWORD -eq 1 ]; then
        get_remote_password
        
        # Copy and verify SSH key
        copy_ssh_key_to_user
        verify_ssh_key_works
    else
        log_info "Skipping key copy (already exists)"
    fi
    
    # Backup before making changes
    backup_remote_sshd_config
    
    # Setup root access
    setup_root_access
    verify_root_access
    
    # Secure SSH configuration
    log_warn "About to disable password authentication!"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_secure_ssh
        final_verification
        show_completion_info
    else
        log_info "Aborted by user (SSH not hardened)"
        log_info "You can still use: ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST"
        exit 0
    fi
}

# Run main function
main "$@"