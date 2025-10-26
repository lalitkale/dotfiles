#!/bin/bash

# System Setup Script for Tuxedo Machine
# This script configures system preferences and settings

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/dotfiles-system-setup-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "======================================"
echo "System Setup Script"
echo "======================================"
echo ""
log_info "Log file: $LOG_FILE"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Set Zsh as default shell
log_info "Setting up default shell..."
if command -v zsh &> /dev/null; then
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$CURRENT_SHELL" != "$(which zsh)" ]; then
        log_info "Changing default shell to Zsh..."
        chsh -s "$(which zsh)" 2>&1 | tee -a "$LOG_FILE"
        log_success "Default shell set to Zsh (requires logout to take effect)"
    else
        log_success "Zsh is already the default shell"
    fi
else
    log_error "Zsh not found. Please install it first."
fi

# Install Oh My Zsh if not present
log_info "Checking for Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    if command -v curl &> /dev/null; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tee -a "$LOG_FILE"
        log_success "Oh My Zsh installed"
    elif command -v wget &> /dev/null; then
        sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tee -a "$LOG_FILE"
        log_success "Oh My Zsh installed"
    else
        log_error "Neither curl nor wget found. Cannot install Oh My Zsh."
    fi
else
    log_success "Oh My Zsh already installed"
fi

# Create common directories
log_info "Creating common directories..."
mkdir -p "$HOME/Projects" 2>&1 | tee -a "$LOG_FILE"
mkdir -p "$HOME/Downloads" 2>&1 | tee -a "$LOG_FILE"
mkdir -p "$HOME/Documents" 2>&1 | tee -a "$LOG_FILE"
mkdir -p "$HOME/.config" 2>&1 | tee -a "$LOG_FILE"
mkdir -p "$HOME/.local/bin" 2>&1 | tee -a "$LOG_FILE"
log_success "Common directories created"

# Add ~/.local/bin to PATH if not present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
    log_info "Adding ~/.local/bin to PATH in .zshrc..."
    echo '' >> "$HOME/.zshrc"
    echo '# Add local bin to PATH' >> "$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    log_success "~/.local/bin added to PATH"
fi

# Set up Git (if not configured)
log_info "Checking Git configuration..."
if command -v git &> /dev/null; then
    if [ -z "$(git config --global user.name)" ]; then
        log_info "Git user name not set. Please configure it manually with:"
        log_info "  git config --global user.name 'Your Name'"
    else
        log_success "Git user name: $(git config --global user.name)"
    fi

    if [ -z "$(git config --global user.email)" ]; then
        log_info "Git user email not set. Please configure it manually with:"
        log_info "  git config --global user.email 'your.email@example.com'"
    else
        log_success "Git user email: $(git config --global user.email)"
    fi
else
    log_error "Git not found. Please install it."
fi

# Set up SSH directory
log_info "Setting up SSH directory..."
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    log_success "SSH directory created"
else
    log_success "SSH directory already exists"
fi

# Budgie Desktop specific settings
if [ "$XDG_CURRENT_DESKTOP" = "Budgie:GNOME" ]; then
    log_info "Detected Budgie desktop environment"
    log_info "Desktop settings will be restored in the next step (restore-configs.sh)"
fi

# Update font cache
log_info "Updating font cache..."
if command -v fc-cache &> /dev/null; then
    fc-cache -f 2>&1 | tee -a "$LOG_FILE"
    log_success "Font cache updated"
fi

echo ""
echo "======================================"
echo "System Setup Complete!"
echo "======================================"
echo ""
log_info "Full log available at: $LOG_FILE"
echo ""
log_info "Important notes:"
log_info "  1. If shell was changed, logout and login for it to take effect"
log_info "  2. Configure Git with your name and email if not set"
log_info "  3. Set up SSH keys if needed"
echo ""
