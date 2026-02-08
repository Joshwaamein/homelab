#!/bin/bash
#
# Zsh Configuration Deployment Script - Production Version
#
# Purpose: Automates zsh, oh-my-zsh, and plugin installation
# Usage: ./deploy-zsh-setup.sh [options]
#
# Features:
# - Installs zsh and oh-my-zsh
# - Installs useful plugins and tools
# - Deploys custom .zshrc configuration
# - Configurable themes and plugins
# - Proper error handling and validation
#
# Author: Homelab Automation
# Version: 2.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ZSH_THEME="${ZSH_THEME:-duellj}"
TARGET_USER="${TARGET_USER:-$USER}"
TARGET_HOME="${TARGET_HOME:-$HOME}"
INSTALL_NVM="${INSTALL_NVM:-true}"
INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-false}"
INSTALL_FUN_STUFF="${INSTALL_FUN_STUFF:-true}"

# Script info
SCRIPT_NAME=$(basename "$0")
VERSION="2.0"

#==============================================================================
# Helper Functions
#==============================================================================

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

show_usage() {
    cat << EOF
${BLUE}Zsh Setup Deployment Script v${VERSION}${NC}

${GREEN}Usage:${NC}
    $SCRIPT_NAME [options]

${GREEN}Options:${NC}
    -h, --help              Show this help message
    -u, --user <username>   Target user (default: current user)
    -t, --theme <theme>     Oh My Zsh theme (default: duellj)
    --skip-nvm              Skip NVM installation
    --install-aws-cli       Install AWS CLI
    --minimal               Minimal install (no fun stuff)

${GREEN}Environment Variables:${NC}
    ZSH_THEME           Oh My Zsh theme name
    TARGET_USER         User to configure
    INSTALL_NVM         Install NVM (true/false)
    INSTALL_AWS_CLI     Install AWS CLI (true/false)
    INSTALL_FUN_STUFF   Install fortune/cowsay/lolcat (true/false)

${GREEN}Examples:${NC}
    $SCRIPT_NAME
    $SCRIPT_NAME --user noble --theme agnoster
    $SCRIPT_NAME --install-aws-cli
    ZSH_THEME=robbyrussell $SCRIPT_NAME

${GREEN}What Gets Installed:${NC}
    ✓ Zsh shell
    ✓ Oh My Zsh framework
    ✓ zsh-syntax-highlighting plugin
    ✓ zsh-autosuggestions plugin
    ✓ fzf (fuzzy finder)
    ✓ NVM (Node Version Manager) [optional]
    ✓ AWS CLI [optional]
    ✓ fortune, cowsay, lolcat [optional]

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -u|--user)
                TARGET_USER="$2"
                TARGET_HOME=$(eval echo "~$TARGET_USER")
                shift 2
                ;;
            -t|--theme)
                ZSH_THEME="$2"
                shift 2
                ;;
            --skip-nvm)
                INSTALL_NVM=false
                shift
                ;;
            --install-aws-cli)
                INSTALL_AWS_CLI=true
                shift
                ;;
            --minimal)
                INSTALL_FUN_STUFF=false
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
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

detect_os() {
    log_step "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
        log_info "Detected: $ID $VERSION_ID"
    else
        log_error "Cannot detect OS"
        exit 1
    fi
}

install_zsh() {
    log_step "Installing zsh..."
    
    if command -v zsh &>/dev/null; then
        log_info "Zsh already installed: $(zsh --version)"
        return 0
    fi
    
    case "$OS_ID" in
        ubuntu|debian)
            apt update
            apt install -y zsh
            ;;
        centos|rhel|almalinux)
            yum install -y zsh
            ;;
        *)
            log_error "Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac
    
    log_success "Zsh installed: $(zsh --version)"
}

install_oh_my_zsh() {
    log_step "Installing Oh My Zsh..."
    
    local zsh_dir="$TARGET_HOME/.oh-my-zsh"
    
    if [ -d "$zsh_dir" ]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi
    
    # Install Oh My Zsh for target user
    sudo -u "$TARGET_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    if [ -d "$zsh_dir" ]; then
        log_success "Oh My Zsh installed"
    else
        log_error "Oh My Zsh installation failed"
        exit 1
    fi
}

install_zsh_plugins() {
    log_step "Installing zsh plugins..."
    
    local custom_plugins="$TARGET_HOME/.oh-my-zsh/custom/plugins"
    
    # zsh-syntax-highlighting
    if [ ! -d "$custom_plugins/zsh-syntax-highlighting" ]; then
        log_info "Installing zsh-syntax-highlighting..."
        sudo -u "$TARGET_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$custom_plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi
    
    # zsh-autosuggestions
    if [ ! -d "$custom_plugins/zsh-autosuggestions" ]; then
        log_info "Installing zsh-autosuggestions..."
        sudo -u "$TARGET_USER" git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$custom_plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_info "zsh-autosuggestions already installed"
    fi
}

install_fzf() {
    log_step "Installing fzf (fuzzy finder)..."
    
    if command -v fzf &>/dev/null; then
        log_info "fzf already installed"
        return 0
    fi
    
    case "$OS_ID" in
        ubuntu|debian)
            apt install -y fzf
            ;;
        centos|rhel|almalinux)
            # Install from git
            sudo -u "$TARGET_USER" git clone --depth 1 https://github.com/junegunn/fzf.git "$TARGET_HOME/.fzf"
            sudo -u "$TARGET_USER" "$TARGET_HOME/.fzf/install" --all
            ;;
    esac
    
    log_success "fzf installed"
}

install_nvm() {
    if [ "$INSTALL_NVM" != "true" ]; then
        log_info "Skipping NVM installation"
        return 0
    fi
    
    log_step "Installing NVM (Node Version Manager)..."
    
    if [ -d "$TARGET_HOME/.nvm" ]; then
        log_info "NVM already installed"
        return 0
    fi
    
    # Install NVM
    sudo -u "$TARGET_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    
    if [ -d "$TARGET_HOME/.nvm" ]; then
        log_success "NVM installed"
    else
        log_warn "NVM installation may have failed"
    fi
}

install_aws_cli() {
    if [ "$INSTALL_AWS_CLI" != "true" ]; then
        log_info "Skipping AWS CLI installation"
        return 0
    fi
    
    log_step "Installing AWS CLI..."
    
    if command -v aws &>/dev/null; then
        log_info "AWS CLI already installed: $(aws --version)"
        return 0
    fi
    
    # Install AWS CLI v2
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    
    log_success "AWS CLI installed: $(aws --version)"
}

install_fun_stuff() {
    if [ "$INSTALL_FUN_STUFF" != "true" ]; then
        log_info "Skipping fun packages"
        return 0
    fi
    
    log_step "Installing fun packages (fortune, cowsay, lolcat)..."
    
    case "$OS_ID" in
        ubuntu|debian)
            apt install -y fortune-mod cowsay lolcat
            ;;
        centos|rhel|almalinux)
            yum install -y fortune-mod cowsay
            # lolcat from gem
            gem install lolcat 2>/dev/null || log_warn "lolcat install failed (gem may not be available)"
            ;;
    esac
    
    log_success "Fun packages installed"
}

deploy_zshrc() {
    log_step "Deploying .zshrc configuration..."
    
    local zshrc="$TARGET_HOME/.zshrc"
    local backup="$zshrc.backup.$(date +%Y%m%d-%H%M%S)"
    
    # Backup existing .zshrc
    if [ -f "$zshrc" ]; then
        log_info "Backing up existing .zshrc to $backup"
        cp "$zshrc" "$backup"
    fi
    
    # Create improved .zshrc
    cat > "$zshrc" << 'ZSHRC'
# ============================================================================
# Zsh Configuration - Homelab Edition
# Generated by deploy-zsh-setup.sh
# ============================================================================

# Path configuration
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"

# Theme - Change this to your preferred theme
# Popular themes: robbyrussell, agnoster, powerlevel10k/powerlevel10k, duellj
ZSH_THEME="THEME_PLACEHOLDER"

# Oh My Zsh update settings
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13

# Plugins to load
# Standard plugins: $ZSH/plugins/
# Custom plugins: $ZSH_CUSTOM/plugins/
plugins=(
    git
    docker
    kubectl
    terraform
    ansible
    sudo
    history
    command-not-found
    zsh-syntax-highlighting
    zsh-autosuggestions
    fzf
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# User Configuration
# ============================================================================

# Preferred editor
export EDITOR='vim'
export VISUAL='vim'

# Language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ============================================================================
# Aliases
# ============================================================================

# General
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Git aliases (additional to oh-my-zsh git plugin)
alias gs='git status'
alias gp='git pull'
alias gP='git push'
alias gc='git commit'
alias gca='git commit -a'
alias gco='git checkout'
alias gl='git log --oneline --graph --decorate'

# Ansible aliases
alias ap='ansible-playbook'
alias av='ansible-vault'
alias ag='ansible-galaxy'
alias ai='ansible-inventory'

# Docker aliases (if docker installed)
if command -v docker &>/dev/null; then
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlogs='docker logs -f'
fi

# System aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias ports='sudo netstat -tulanp'
alias myip='curl -s ifconfig.me'

# Quick navigation (customize for your environment)
alias cdans='cd /opt/ansible/noble-semaphore'
alias cdscripts='cd /opt/scripts'

# ============================================================================
# Functions
# ============================================================================

# Quick git commit and push
function gcp() {
    git add -A
    git commit -m "$1"
    git push
}

# Create directory and cd into it
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick search in history
function h() {
    if [ -z "$1" ]; then
        history
    else
        history | grep "$1"
    fi
}

# ============================================================================
# Tool Integration
# ============================================================================

# Load NVM (Node Version Manager)
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# FZF integration
if command -v fzf &>/dev/null; then
    # fzf key bindings and fuzzy completion
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    
    # Use fd instead of find if available
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# AWS CLI completion
if command -v aws &>/dev/null && command -v aws_zsh_completer.sh &>/dev/null; then
    source aws_zsh_completer.sh
fi

# Kubectl completion
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
    alias k=kubectl
    complete -F __start_kubectl k
fi

# Terraform completion
if command -v terraform &>/dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C /usr/bin/terraform terraform
fi

# ============================================================================
# Custom Prompt Enhancements
# ============================================================================

# Show exit code of last command if non-zero
setopt PROMPT_SUBST
RPROMPT='%(?..[%F{red}%?%f])'

# ============================================================================
# Welcome Message
# ============================================================================

# Fun startup message (if fortune/cowsay/lolcat installed)
if command -v fortune &>/dev/null && command -v cowsay &>/dev/null && command -v lolcat &>/dev/null; then
    fortune | cowsay | lolcat
elif command -v fortune &>/dev/null; then
    fortune
fi

# Show system info
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Welcome to $(hostname -s) "
echo "║  $(date '+%A, %B %d, %Y - %H:%M:%S')"
echo "╚════════════════════════════════════════╝"
echo ""

# ============================================================================
# Performance optimizations
# ============================================================================

# Disable automatic update prompts during shell startup
DISABLE_AUTO_UPDATE="true"

# Speed up compinit
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ============================================================================
# Custom additions
# ============================================================================

# Add your custom configuration below this line
# This section won't be overwritten by the deployment script

ZSHRC
    
    # Replace theme placeholder
    sed -i "s/THEME_PLACEHOLDER/$ZSH_THEME/" "$zshrc"
    
    # Set ownership
    chown "$TARGET_USER:$TARGET_USER" "$zshrc"
    chmod 644 "$zshrc"
    
    log_success ".zshrc deployed"
}

change_default_shell() {
    log_step "Changing default shell to zsh..."
    
    local current_shell=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    local zsh_path=$(command -v zsh)
    
    if [ "$current_shell" = "$zsh_path" ]; then
        log_info "Default shell is already zsh"
        return 0
    fi
    
    if chsh -s "$zsh_path" "$TARGET_USER"; then
        log_success "Default shell changed to zsh"
        log_warn "Changes will take effect on next login"
    else
        log_error "Failed to change default shell"
        log_info "You can change manually with: chsh -s $(which zsh)"
    fi
}

install_system_dependencies() {
    log_step "Installing system dependencies..."
    
    case "$OS_ID" in
        ubuntu|debian)
            apt install -y \
                git \
                curl \
                wget \
                unzip \
                build-essential \
                python3-pip
            ;;
        centos|rhel|almalinux)
            yum groupinstall -y "Development Tools"
            yum install -y \
                git \
                curl \
                wget \
                unzip \
                python3-pip
            ;;
    esac
    
    log_success "System dependencies installed"
}

show_completion_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Zsh setup completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Configuration Summary:"
    log_info "  User: $TARGET_USER"
    log_info "  Home: $TARGET_HOME"
    log_info "  Theme: $ZSH_THEME"
    log_info "  Config: $TARGET_HOME/.zshrc"
    echo ""
    log_info "Installed Components:"
    echo "  ✓ Zsh shell"
    echo "  ✓ Oh My Zsh framework"
    echo "  ✓ zsh-syntax-highlighting plugin"
    echo "  ✓ zsh-autosuggestions plugin"
    echo "  ✓ fzf (fuzzy finder)"
    [ "$INSTALL_NVM" = "true" ] && echo "  ✓ NVM (Node Version Manager)"
    [ "$INSTALL_AWS_CLI" = "true" ] && echo "  ✓ AWS CLI"
    [ "$INSTALL_FUN_STUFF" = "true" ] && echo "  ✓ fortune, cowsay, lolcat"
    echo ""
    log_info "Useful Plugins Enabled:"
    echo "  • git - Git aliases and completions"
    echo "  • docker - Docker aliases and completions"
    echo "  • kubectl - Kubernetes completions"
    echo "  • terraform - Terraform completions"
    echo "  • ansible - Ansible completions"
    echo "  • sudo - Press ESC twice to add sudo to command"
    echo "  • history - History utilities"
    echo "  • command-not-found - Suggests package for missing commands"
    echo "  • zsh-syntax-highlighting - Syntax highlighting"
    echo "  • zsh-autosuggestions - Command suggestions"
    echo "  • fzf - Fuzzy finder integration"
    echo ""
    log_warn "To start using zsh:"
    echo "  ${GREEN}exec zsh${NC}  or  ${GREEN}su - $TARGET_USER${NC}"
    echo ""
    log_info "Customize your config:"
    echo "  ${GREEN}nano $TARGET_HOME/.zshrc${NC}"
    echo ""
}

#==============================================================================
# Main Script
#==============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BLUE}Zsh Setup Deployment v${VERSION}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Display configuration
    log_info "Configuration:"
    log_info "  Target User: $TARGET_USER"
    log_info "  Theme: $ZSH_THEME"
    log_info "  Install NVM: $INSTALL_NVM"
    log_info "  Install AWS CLI: $INSTALL_AWS_CLI"
    log_info "  Install Fun Stuff: $INSTALL_FUN_STUFF"
    echo ""
    
    # Pre-flight checks
    check_root
    detect_os
    install_system_dependencies
    
    # Install zsh and framework
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_fzf
    
    # Optional installations
    install_nvm
    install_aws_cli
    install_fun_stuff
    
    # Deploy configuration
    deploy_zshrc
    change_default_shell
    
    # Show completion info
    show_completion_info
}

# Run main function
main "$@"