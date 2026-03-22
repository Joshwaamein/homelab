#!/bin/bash
#
# Zabbix Agent Deployment Script - Production Version
#
# Purpose: Automates Zabbix agent installation with safety checks
# Usage: ./zabbixdeploy.sh [options]
#
# Features:
# - Proper error handling and validation
# - Configurable via environment variables
# - Check if already installed
# - Download verification
# - Automatic cleanup
# - Color-coded output and logging
#
# Author: Homelab Automation
# Version: 2.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (can be overridden by environment variables)
ZABBIX_SERVER="${ZABBIX_SERVER:-100.85.45.123}"
ZABBIX_VERSION="${ZABBIX_VERSION:-7.2.4}"
INSTALL_DIR="${INSTALL_DIR:-/opt/zabbix}"
CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"
LOG_DIR="/var/log/zabbix"
RUN_DIR="/var/run/zabbix"

# Script info
SCRIPT_NAME=$(basename "$0")
VERSION="2.0"

# Temporary directory (will be cleaned up automatically)
TEMP_DIR=$(mktemp -d)

#==============================================================================
# Cleanup Handler
#==============================================================================

cleanup() {
    local exit_code=$?
    if [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
    exit $exit_code
}

trap cleanup EXIT INT TERM

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
${BLUE}Zabbix Agent Deployment Script v${VERSION}${NC}

${GREEN}Usage:${NC}
    $SCRIPT_NAME [options]

${GREEN}Options:${NC}
    -h, --help          Show this help message
    -s, --server        Zabbix server IP (default: $ZABBIX_SERVER)
    -v, --version       Zabbix version (default: $ZABBIX_VERSION)
    -r, --reinstall     Force reinstall even if already installed

${GREEN}Environment Variables:${NC}
    ZABBIX_SERVER       Zabbix server IP address
    ZABBIX_VERSION      Version to install (e.g., 7.2.4)
    INSTALL_DIR         Installation directory (default: /opt/zabbix)

${GREEN}Examples:${NC}
    $SCRIPT_NAME
    $SCRIPT_NAME --server 192.168.1.50
    $SCRIPT_NAME --version 7.0.0 --server 10.0.0.100
    ZABBIX_SERVER=192.168.1.50 $SCRIPT_NAME

${GREEN}Features:${NC}
    ✓ Checks if already installed
    ✓ Downloads and verifies Zabbix agent
    ✓ Creates system user
    ✓ Configures systemd service
    ✓ Validates installation
    ✓ Automatic cleanup on exit

${GREEN}Prerequisites:${NC}
    - wget or curl
    - sudo privileges
    - systemd-based system

EOF
}

parse_arguments() {
    local force_reinstall=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--server)
                ZABBIX_SERVER="$2"
                shift 2
                ;;
            -v|--version)
                ZABBIX_VERSION="$2"
                shift 2
                ;;
            -r|--reinstall)
                force_reinstall=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Export for use in other functions
    export FORCE_REINSTALL=$force_reinstall
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

check_dependencies() {
    log_step "Checking dependencies..."
    
    local missing=()
    
    # Check for download tools
    if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
        missing+=("wget or curl")
    fi
    
    # Check for systemd
    if ! command -v systemctl &>/dev/null; then
        missing+=("systemd")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
    
    log_success "All dependencies present"
}

check_already_installed() {
    log_step "Checking if Zabbix agent is already installed..."
    
    if systemctl is-active --quiet zabbix-agent 2>/dev/null; then
        log_warn "Zabbix agent is already installed and running"
        
        if [ "${FORCE_REINSTALL:-false}" = true ]; then
            log_info "Force reinstall requested, continuing..."
            return 0
        fi
        
        echo ""
        read -p "Reinstall anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
        
        log_info "Stopping existing service..."
        systemctl stop zabbix-agent || true
    else
        log_info "No existing installation found"
    fi
}

get_download_url() {
    # Construct download URL based on version
    local base_url="https://cdn.zabbix.com/zabbix/binaries/stable"
    local major_minor=$(echo "$ZABBIX_VERSION" | cut -d. -f1,2)
    local filename="zabbix_agent-${ZABBIX_VERSION}-linux-3.0-amd64-static.tar.gz"
    
    echo "${base_url}/${major_minor}/${ZABBIX_VERSION}/${filename}"
}

download_file() {
    local url=$1
    local output=$2
    
    log_info "Downloading from: $url"
    
    if command -v wget &>/dev/null; then
        if wget -q --show-progress --timeout=30 -O "$output" "$url"; then
            return 0
        fi
    elif command -v curl &>/dev/null; then
        if curl -fSL --progress-bar --connect-timeout 30 -o "$output" "$url"; then
            return 0
        fi
    fi
    
    return 1
}

download_and_verify() {
    log_step "Downloading Zabbix agent..."
    
    local download_url=$(get_download_url)
    local output_file="$TEMP_DIR/zabbix_agent.tar.gz"
    
    if ! download_file "$download_url" "$output_file"; then
        log_error "Download failed"
        log_error "URL: $download_url"
        log_error "Please check:"
        log_error "  - Internet connectivity"
        log_error "  - Zabbix version exists ($ZABBIX_VERSION)"
        log_error "  - URL is accessible"
        exit 1
    fi
    
    # Verify download
    if [ ! -s "$output_file" ]; then
        log_error "Downloaded file is empty or missing"
        exit 1
    fi
    
    local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1000000 ]; then  # Less than 1MB is suspicious
        log_warn "Downloaded file seems too small ($file_size bytes)"
        log_warn "This might indicate a problem"
    fi
    
    log_success "Download successful ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "$file_size bytes"))"
    
    echo "$output_file"
}

extract_archive() {
    local archive=$1
    
    log_step "Extracting archive..."
    
    if ! tar -xzf "$archive" -C "$TEMP_DIR"; then
        log_error "Failed to extract archive"
        log_error "The downloaded file may be corrupted"
        exit 1
    fi
    
    # Find extracted directory
    local extracted_dir=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "zabbix_agent-*" | head -n1)
    
    if [ -z "$extracted_dir" ]; then
        log_error "Could not find extracted directory"
        exit 1
    fi
    
    log_success "Archive extracted to: $extracted_dir"
    echo "$extracted_dir"
}

create_directories() {
    log_step "Creating necessary directories..."
    
    mkdir -p /etc/zabbix
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$RUN_DIR"
    
    log_success "Directories created"
}

create_zabbix_user() {
    log_step "Creating zabbix user..."
    
    if id -u zabbix >/dev/null 2>&1; then
        log_info "User 'zabbix' already exists"
    else
        if useradd -r -M -s /bin/false zabbix; then
            log_success "User 'zabbix' created"
        else
            log_error "Failed to create user 'zabbix'"
            exit 1
        fi
    fi
}

install_agent() {
    local extracted_dir=$1
    
    log_step "Installing Zabbix agent..."
    
    # Copy binaries
    if [ ! -d "$extracted_dir/sbin" ] || [ ! -f "$extracted_dir/sbin/zabbix_agentd" ]; then
        log_error "Zabbix agent binary not found in extracted archive"
        exit 1
    fi
    
    cp -r "$extracted_dir"/* "$INSTALL_DIR/"
    
    # Verify installation
    if [ ! -f "$INSTALL_DIR/sbin/zabbix_agentd" ]; then
        log_error "Installation failed - binary not found"
        exit 1
    fi
    
    log_success "Agent files installed to $INSTALL_DIR"
}

create_configuration() {
    log_step "Creating configuration file..."
    
    local hostname=$(hostname)
    
    cat > "$CONFIG_FILE" << EOF
# Zabbix Agent Configuration
# Generated by $SCRIPT_NAME v$VERSION on $(date)

# Process ID file
PidFile=$RUN_DIR/zabbix_agentd.pid

# Log file
LogFile=$LOG_DIR/zabbix_agentd.log
LogFileSize=0

# Server and active check configuration
Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER

# Hostname (must be unique and match the hostname in Zabbix server)
Hostname=$hostname

# Include additional configuration files
Include=/etc/zabbix/zabbix_agentd.d/*.conf

# Timeout for external checks
Timeout=10

# Allow all remote commands (0=disabled, 1=enabled)
# WARNING: This is a security risk, only enable if needed
EnableRemoteCommands=0

# Log level
# 0 - basic information
# 1 - critical
# 2 - error
# 3 - warning
# 4 - debug
# 5 - trace
DebugLevel=3
EOF
    
    # Create conf.d directory
    mkdir -p /etc/zabbix/zabbix_agentd.d
    
    log_success "Configuration created: $CONFIG_FILE"
}

set_permissions() {
    log_step "Setting file permissions..."
    
    chown -R zabbix:zabbix "$LOG_DIR"
    chown -R zabbix:zabbix "$RUN_DIR"
    chown zabbix:zabbix "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
    
    log_success "Permissions set"
}

create_systemd_service() {
    log_step "Creating systemd service..."
    
    cat > /etc/systemd/system/zabbix-agent.service << EOF
[Unit]
Description=Zabbix Agent
After=network.target
Documentation=https://www.zabbix.com/documentation

[Service]
Type=simple
User=zabbix
Group=zabbix
ExecStart=$INSTALL_DIR/sbin/zabbix_agentd -c $CONFIG_FILE -f
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

# Security settings
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$LOG_DIR $RUN_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "Systemd service created"
}

enable_and_start_service() {
    log_step "Enabling and starting service..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    if systemctl enable zabbix-agent; then
        log_success "Service enabled"
    else
        log_error "Failed to enable service"
        exit 1
    fi
    
    # Start service
    if systemctl start zabbix-agent; then
        log_success "Service started"
    else
        log_error "Failed to start service"
        log_error "Check logs: journalctl -u zabbix-agent -n 50"
        exit 1
    fi
    
    # Wait a moment for service to stabilize
    sleep 2
}

verify_installation() {
    log_step "Verifying installation..."
    
    # Check if service is active
    if systemctl is-active --quiet zabbix-agent; then
        log_success "Service is running"
    else
        log_error "Service is not running"
        log_error "Status:"
        systemctl status zabbix-agent --no-pager || true
        log_error "Logs:"
        journalctl -u zabbix-agent -n 20 --no-pager || true
        exit 1
    fi
    
    # Check if agent is listening
    if [ -f "$RUN_DIR/zabbix_agentd.pid" ]; then
        log_success "PID file exists"
    else
        log_warn "PID file not found (may be normal on some systems)"
    fi
    
    # Test configuration
    if "$INSTALL_DIR/sbin/zabbix_agentd" -c "$CONFIG_FILE" -t &>/dev/null; then
        log_success "Configuration test passed"
    else
        log_warn "Configuration test had warnings (check logs)"
    fi
    
    log_success "Installation verified successfully"
}

show_completion_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Zabbix Agent installation completed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Version: $ZABBIX_VERSION"
    log_info "Server: $ZABBIX_SERVER"
    log_info "Hostname: $(hostname)"
    log_info "Installation: $INSTALL_DIR"
    log_info "Configuration: $CONFIG_FILE"
    echo ""
    log_info "Service Commands:"
    echo "  ${GREEN}systemctl status zabbix-agent${NC}  - Check status"
    echo "  ${GREEN}systemctl stop zabbix-agent${NC}    - Stop service"
    echo "  ${GREEN}systemctl start zabbix-agent${NC}   - Start service"
    echo "  ${GREEN}systemctl restart zabbix-agent${NC} - Restart service"
    echo ""
    log_info "Logs:"
    echo "  ${GREEN}journalctl -u zabbix-agent -f${NC}  - Follow logs"
    echo "  ${GREEN}tail -f $LOG_DIR/zabbix_agentd.log${NC}  - Agent log file"
    echo ""
    log_info "Configuration:"
    echo "  ${GREEN}$CONFIG_FILE${NC}"
    echo ""
    log_warn "Next Steps:"
    log_warn "1. Add this host to Zabbix server with hostname: $(hostname)"
    log_warn "2. Ensure firewall allows connection to Zabbix server"
    log_warn "3. Verify agent is reporting to server"
    echo ""
}

#==============================================================================
# Main Script
#==============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BLUE}Zabbix Agent Deployment v${VERSION}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Display configuration
    log_info "Configuration:"
    log_info "  Zabbix Server: $ZABBIX_SERVER"
    log_info "  Version: $ZABBIX_VERSION"
    log_info "  Install Dir: $INSTALL_DIR"
    echo ""
    
    # Pre-flight checks
    check_root
    check_dependencies
    check_already_installed
    
    # Download and extract
    local archive=$(download_and_verify)
    local extracted_dir=$(extract_archive "$archive")
    
    # Install
    create_directories
    create_zabbix_user
    install_agent "$extracted_dir"
    create_configuration
    set_permissions
    
    # Configure service
    create_systemd_service
    enable_and_start_service
    
    # Verify
    verify_installation
    
    # Show completion info
    show_completion_info
}

# Run main function
main "$@"