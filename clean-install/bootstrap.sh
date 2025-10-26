#!/bin/bash

# Bootstrap Script for Clean Tuxedo Machine Installation
# This script orchestrates the complete installation and configuration process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/bootstrap-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_info() {
    log "${YELLOW}→ $1${NC}"
}

log_header() {
    log "${BOLD}${BLUE}$1${NC}"
}

print_banner() {
    echo ""
    log "${BOLD}${BLUE}======================================"
    log "  Tuxedo Machine Bootstrap Script"
    log "======================================${NC}"
    echo ""
}

print_section() {
    echo ""
    log "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "  $1"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root."
    exit 1
fi

print_banner
log_info "Master log file: $LOG_FILE"
log_info "Installation started at: $(date)"
echo ""

log_info "This script will:"
log_info "  1. Update system packages"
log_info "  2. Install all required packages"
log_info "  3. Configure system settings"
log_info "  4. Restore your dotfiles and configurations"
echo ""

# Ask for confirmation
read -p "Do you want to proceed with the installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled by user"
    exit 0
fi

echo ""
log_info "Starting installation..."
echo ""

# Step 1: System Update
print_section "Step 1/4: System Update"
log_info "Updating package lists and upgrading existing packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"
log_success "Package lists updated"

read -p "Do you want to upgrade existing packages? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Upgrading packages (this may take a while)..."
    sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
    log_success "System packages upgraded"
else
    log_info "Skipping package upgrade"
fi

# Step 2: Install Packages
print_section "Step 2/4: Package Installation"
if [ -f "$SCRIPT_DIR/scripts/install-packages.sh" ]; then
    log_info "Installing packages from package lists..."
    bash "$SCRIPT_DIR/scripts/install-packages.sh" 2>&1 | tee -a "$LOG_FILE"
    log_success "Package installation complete"
else
    log_error "Package installation script not found!"
    exit 1
fi

# Step 3: System Configuration
print_section "Step 3/4: System Configuration"
if [ -f "$SCRIPT_DIR/scripts/setup-system.sh" ]; then
    log_info "Configuring system settings..."
    bash "$SCRIPT_DIR/scripts/setup-system.sh" 2>&1 | tee -a "$LOG_FILE"
    log_success "System configuration complete"
else
    log_error "System setup script not found!"
    exit 1
fi

# Step 4: Restore Configurations
print_section "Step 4/4: Restore Dotfiles"
if [ -f "$SCRIPT_DIR/scripts/restore-configs.sh" ]; then
    log_info "Restoring dotfiles and configurations..."
    bash "$SCRIPT_DIR/scripts/restore-configs.sh" 2>&1 | tee -a "$LOG_FILE"
    log_success "Configuration restore complete"
else
    log_error "Configuration restore script not found!"
    exit 1
fi

# Final Summary
print_section "Installation Complete!"

log_success "All steps completed successfully!"
echo ""
log_info "Installation finished at: $(date)"
log_info "Complete log available at: $LOG_FILE"
echo ""

log_header "Next Steps:"
log_info "  1. Review the log file for any errors or warnings"
log_info "  2. Restart your terminal or run: source ~/.zshrc"
log_info "  3. Log out and log back in to apply all changes"
log_info "  4. Configure Git with your credentials if needed:"
log_info "       git config --global user.name 'Your Name'"
log_info "       git config --global user.email 'your.email@example.com'"
log_info "  5. Set up SSH keys if needed"
echo ""

read -p "Do you want to reboot now? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rebooting system..."
    sudo reboot
else
    log_info "Please reboot manually when ready"
fi
