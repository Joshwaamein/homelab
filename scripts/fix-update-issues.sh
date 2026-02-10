#!/bin/bash
#
# Script to fix common update issues
# Usage: ./fix-update-issues.sh <issue_number> <host_ip>
#
# Issues:
#   1 - Raspberry Pi disk full (/run tmpfs)
#   3 - Apt cache failures
#
# Version: 1.0

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SSH_KEY="${SSH_KEY:-$HOME/.ssh/ansible}"

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

show_usage() {
    cat << EOF
${BLUE}Fix Update Issues Script${NC}

${GREEN}Usage:${NC}
    $0 <issue_number> <host_ip>

${GREEN}Issues:${NC}
    1 - Fix Raspberry Pi disk full (/run tmpfs)
    3 - Fix apt cache failures

${GREEN}Examples:${NC}
    $0 1 100.102.244.34    # Fix Raspberry Pi
    $0 3 100.117.78.117    # Fix pve-data apt cache
    $0 3 100.89.11.64      # Fix pbs-t14 apt cache

EOF
}

fix_raspberry_pi_disk() {
    local HOST=$1
    log_info "Fixing Raspberry Pi disk space issue on $HOST..."
    
    echo ""
    log_info "Step 1: Checking disk usage..."
    ssh -i "$SSH_KEY" root@"$HOST" "df -h /run" || true
    
    echo ""
    log_info "Step 2: Clearing journal logs..."
    ssh -i "$SSH_KEY" root@"$HOST" "journalctl --vacuum-size=5M" || log_warn "Failed to vacuum journals"
    
    echo ""
    log_info "Step 3: Cleaning apt cache..."
    ssh -i "$SSH_KEY" root@"$HOST" "apt-get clean" || log_warn "Failed to clean apt cache"
    
    echo ""
    log_info "Step 4: Removing old logs..."
    ssh -i "$SSH_KEY" root@"$HOST" "find /var/log -type f -name '*.gz' -delete" || log_warn "Failed to remove old logs"
    ssh -i "$SSH_KEY" root@"$HOST" "find /var/log -type f -name '*.old' -delete" || log_warn "Failed to remove .old files"
    
    echo ""
    log_info "Step 5: Checking disk usage again..."
    ssh -i "$SSH_KEY" root@"$HOST" "df -h /run"
    
    echo ""
    log_info "Step 6: Attempting to reload systemd..."
    if ssh -i "$SSH_KEY" root@"$HOST" "systemctl daemon-reexec"; then
        log_success "Systemd reloaded successfully"
    else
        log_error "Failed to reload systemd - may need manual intervention"
    fi
    
    echo ""
    log_info "Step 7: Fixing broken packages..."
    if ssh -i "$SSH_KEY" root@"$HOST" "dpkg --configure -a"; then
        log_success "Package configuration fixed"
    else
        log_error "Failed to fix packages - may need manual intervention"
    fi
    
    echo ""
    log_success "Raspberry Pi disk cleanup complete!"
    log_info "You may need to reboot the Pi if issues persist"
}

fix_apt_cache() {
    local HOST=$1
    log_info "Fixing apt cache issues on $HOST..."
    
    echo ""
    log_info "Step 1: Removing corrupted apt lists..."
    ssh -i "$SSH_KEY" root@"$HOST" "rm -rf /var/lib/apt/lists/*"
    
    echo ""
    log_info "Step 2: Cleaning apt cache..."
    ssh -i "$SSH_KEY" root@"$HOST" "apt-get clean"
    
    echo ""
    log_info "Step 3: Updating apt cache..."
    if ssh -i "$SSH_KEY" root@"$HOST" "apt-get update"; then
        log_success "Apt cache updated successfully"
    else
        log_error "Failed to update apt cache"
        log_error "Check internet connectivity and repository configuration"
        return 1
    fi
    
    echo ""
    log_success "Apt cache fix complete!"
}

main() {
    if [ $# -ne 2 ]; then
        show_usage
        exit 1
    fi
    
    local ISSUE=$1
    local HOST=$2
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BLUE}Fix Update Issues Script${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    case $ISSUE in
        1)
            fix_raspberry_pi_disk "$HOST"
            ;;
        3)
            fix_apt_cache "$HOST"
            ;;
        *)
            log_error "Unknown issue number: $ISSUE"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"