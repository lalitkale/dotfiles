#!/bin/bash

# Configuration Restore Script
# This script restores configurations from the tuxedo dotfiles directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUXEDO_DIR="$SCRIPT_DIR/../../tuxedo"
LOG_FILE="$HOME/dotfiles-restore-$(date +%Y%m%d-%H%M%S).log"

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
echo "Configuration Restore Script"
echo "======================================"
echo ""
log_info "Log file: $LOG_FILE"
echo ""

# Check if tuxedo directory exists
if [ ! -d "$TUXEDO_DIR" ]; then
    log_error "Tuxedo dotfiles directory not found at: $TUXEDO_DIR"
    log_error "Please ensure the tuxedo dotfiles are in the correct location."
    exit 1
fi

log_info "Using dotfiles from: $TUXEDO_DIR"
echo ""

# Check if the restore script exists in tuxedo directory
if [ -f "$TUXEDO_DIR/restore.sh" ]; then
    log_info "Running the restore script from tuxedo dotfiles..."
    cd "$TUXEDO_DIR"
    bash "$TUXEDO_DIR/restore.sh" 2>&1 | tee -a "$LOG_FILE"
    log_success "Configuration restore complete"
else
    log_error "Restore script not found in tuxedo directory"
    log_info "Attempting manual restoration..."

    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: $BACKUP_DIR"

    # Restore shell configurations
    log_info "Restoring shell configurations..."
    for file in .zshrc .bashrc .aliases .bash_aliases; do
        if [ -f "$TUXEDO_DIR/$file" ]; then
            if [ -f "$HOME/$file" ]; then
                cp "$HOME/$file" "$BACKUP_DIR/"
                log_info "  Backed up existing $file"
            fi
            cp "$TUXEDO_DIR/$file" "$HOME/$file"
            log_success "  Restored $file"
        fi
    done

    # Restore git configuration
    log_info "Restoring git configuration..."
    if [ -f "$TUXEDO_DIR/.gitconfig" ]; then
        if [ -f "$HOME/.gitconfig" ]; then
            cp "$HOME/.gitconfig" "$BACKUP_DIR/"
            log_info "  Backed up existing .gitconfig"
        fi
        cp "$TUXEDO_DIR/.gitconfig" "$HOME/.gitconfig"
        log_success "  Restored .gitconfig"
    fi

    # Restore Ghostty configuration
    log_info "Restoring Ghostty configuration..."
    if [ -d "$TUXEDO_DIR/ghostty" ]; then
        mkdir -p "$HOME/.config"
        if [ -d "$HOME/.config/ghostty" ]; then
            cp -r "$HOME/.config/ghostty" "$BACKUP_DIR/"
            log_info "  Backed up existing ghostty config"
        fi
        cp -r "$TUXEDO_DIR/ghostty" "$HOME/.config/"
        log_success "  Restored ghostty config"
    fi

    # Restore desktop environment settings
    log_info "Restoring desktop environment settings..."
    if command -v dconf &> /dev/null; then
        if [ -f "$TUXEDO_DIR/budgie-panel.dconf" ]; then
            dconf load /com/solus-project/budgie-panel/ < "$TUXEDO_DIR/budgie-panel.dconf" 2>&1 | tee -a "$LOG_FILE"
            log_success "  Restored Budgie panel settings"
        fi

        if [ -f "$TUXEDO_DIR/budgie-wm.dconf" ]; then
            dconf load /com/solus-project/budgie-wm/ < "$TUXEDO_DIR/budgie-wm.dconf" 2>&1 | tee -a "$LOG_FILE"
            log_success "  Restored Budgie WM settings"
        fi

        if [ -f "$TUXEDO_DIR/gnome-settings.dconf" ]; then
            dconf load /org/gnome/ < "$TUXEDO_DIR/gnome-settings.dconf" 2>&1 | tee -a "$LOG_FILE"
            log_success "  Restored GNOME settings"
        fi
    else
        log_error "  dconf not found, skipping desktop settings"
    fi
fi

echo ""
echo "======================================"
echo "Configuration Restore Complete!"
echo "======================================"
echo ""
log_info "Full log available at: $LOG_FILE"
echo ""
log_info "Next steps:"
log_info "  1. Restart your terminal or run 'source ~/.zshrc'"
log_info "  2. Log out and log back in to apply desktop environment changes"
echo ""
