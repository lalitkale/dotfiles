#!/bin/bash

# Tuxedo Machine Configuration Restore Script
# This script restores dotfiles and configurations backed up from your Tuxedo machine

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo "======================================"
echo "Tuxedo Configuration Restore Script"
echo "======================================"
echo ""

# Create backup directory for existing configs
echo "Creating backup directory at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to safely copy files
backup_and_restore() {
    local source="$1"
    local dest="$2"

    if [ -e "$dest" ]; then
        echo "  Backing up existing $dest"
        cp -r "$dest" "$BACKUP_DIR/"
    fi

    echo "  Restoring $dest"
    cp -r "$source" "$dest"
}

# Restore shell configurations
echo ""
echo "Restoring shell configurations..."
backup_and_restore "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_restore "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
backup_and_restore "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
backup_and_restore "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"

# Restore git configuration
echo ""
echo "Restoring git configuration..."
backup_and_restore "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Restore Ghostty terminal configuration
echo ""
echo "Restoring Ghostty terminal configuration..."
mkdir -p "$HOME/.config"
backup_and_restore "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# Restore Budgie and GNOME settings
echo ""
echo "Restoring desktop environment settings..."
if command -v dconf &> /dev/null; then
    if [ -f "$DOTFILES_DIR/budgie-panel.dconf" ]; then
        echo "  Restoring Budgie panel settings"
        dconf load /com/solus-project/budgie-panel/ < "$DOTFILES_DIR/budgie-panel.dconf"
    fi

    if [ -f "$DOTFILES_DIR/budgie-wm.dconf" ]; then
        echo "  Restoring Budgie WM settings"
        dconf load /com/solus-project/budgie-wm/ < "$DOTFILES_DIR/budgie-wm.dconf"
    fi

    if [ -f "$DOTFILES_DIR/gnome-settings.dconf" ]; then
        echo "  Restoring GNOME settings"
        dconf load /org/gnome/ < "$DOTFILES_DIR/gnome-settings.dconf"
    fi
else
    echo "  Warning: dconf not found, skipping desktop environment settings"
fi

echo ""
echo "======================================"
echo "Restore Complete!"
echo "======================================"
echo ""
echo "Your previous configurations have been backed up to:"
echo "  $BACKUP_DIR"
echo ""
echo "You may need to:"
echo "  1. Restart your terminal or run 'source ~/.zshrc' to apply shell changes"
echo "  2. Log out and log back in to apply desktop environment changes"
echo ""
